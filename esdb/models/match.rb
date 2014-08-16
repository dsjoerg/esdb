class ESDB::Match < Sequel::Model(:esdb_matches)

  plugin :many_through_many

  one_to_many :replays, :class => 'ESDB::Sc2::Match::Replay'
  one_to_many :matches_deleted, :class => 'ESDB::Match_Deleted'
  one_to_many :summaries, :class => 'ESDB::Sc2::Match::Summary'
  one_to_many :entities, :class => 'ESDB::Sc2::Match::Entity'
  many_to_one :map, :class => 'ESDB::Sc2::Map'
  one_to_many :matchups, :class => 'ESDB::Sc2::Match::Matchup'

  many_through_many :identities, [[:esdb_sc2_match_entities, :match_id, :id], [:esdb_identity_entities, :entity_id, :identity_id]]

  # http://sequel.rubyforge.org/rdoc-plugins/classes/Sequel/Plugins/AssociationDependencies.html
  plugin :association_dependencies, :entities=>:destroy, :matchups=>:destroy, :replays=>:nullify, :summaries=>:nullify


  subset :finalized, :state => 1
  subset :unfinalized, :state => nil

  # Cache Invalidation
  # called after save and at the end of postprocess!

  def invalidate_cache!
    Garner::Cache::ObjectIdentity.invalidate(ESDB::Match, self.id)
    Garner::Cache::ObjectIdentity.invalidate(ESDB::Match)

    # Also invalidate for all identities
    identities_dataset.select(:id).qualify.each do |identity|
      Garner::Cache::ObjectIdentity.invalidate(ESDB::Identity, identity.id)
    end
  end

  def after_save
    invalidate_cache!
  end

  # Returns whether the Match has been finalized. Final matches should not
  # be modified.
  def final?
    state == 1
  end

  def replays?
    replays_count > 0
  end

  def summaries?
    summaries_count > 0
  end

  def deleted?
    matches_deleted.count > 0
  end

  def avg(stat = :apm)
    stat = stat.to_sym
    case stat
    when :apm, :wpm
      minutes.avg(stat)
    else
      0.0
    end
  end

  # returns a list of the unique matchup numbers that exist for this match
  def compute_matchups
    matchups = []
    entities_races = entities_dataset.select(:team, :race).all
    entities_races.each do |e1|
      entities_races.each do |e2|
        if e1.team != e2.team
          matchup = ESDB::Sc2::Match::Matchup.matchup_id(e1.race.downcase, e2.race.downcase)
          if matchup.present?
            matchups << ESDB::Sc2::Match::Matchup.matchup_id(e1.race.downcase, e2.race.downcase)
          end
        end
      end
    end
    matchups.uniq
  end

  def accumulate!(replay)
    self.this.update(:replays_count => Sequel.lit('replays_count + 1')
                     )

    # TODO add a daily job that re-computes this aggregate for matches
    # that have had any summaries or replays uploaded in the past day.
  end

  # Postprocessing for the Match that we don't want in the replay parser
  # Prime example being the average_league - the replay parser creates 
  # identities that might not be scraped when it runs, and so it has no way of
  # knowing or setting the average league.
  #
  # TODO: it should also run whenever an identity belonging to this match has
  # been scraped for the first time.
  #
  def postprocess!
    # destroy and rebuild our set of matchups
    self.matchups_dataset.delete
    matchups_hash = self.compute_matchups.collect{|matchup| {:match_id => self.id, :matchup => matchup}}
    DB[:esdb_sc2_match_matchups].multi_insert(matchups_hash)

    # Sync "sum caches"
    self.summaries_count = summaries_dataset.count

    # HAX: if we have a replay, we'll pull in the gateway from
    # identities Any replay should have identities and they must have
    # a gateway.
    if !self.gateway
      first_identity = identities_dataset.select(:gateway).first
      if first_identity.present?
        self.gateway = first_identity.gateway
      end
    end

    # if we have leagueinfo for the players, save it in the entities now
    #
    # this also gets done after scraping an identity, but we cant
    # assume that all identities in this match will get scraped any
    # time soon -- maybe they were scraped an hour ago, so they wont
    # be scraped again for another 23 hours.
    #
    entities.where(:highest_league => nil).all.each do |entity|
      sc2id = entity.sc2_identity
      entity.highest_league = sc2id.current_highest_league
      if sc2id.current_highest_type.present?
        entity.highest_league_gametype = sc2id.current_highest_type[0].to_i
      end
      entity.save_changes
    end

    # Set average league for this match from entities highest_league
    # TODO: obviously SC2 related and shouldn't be in ESDB::Match
    entity_leagues = entities_dataset.select(:highest_league).all.collect(&:highest_league)
    non_nil_leagues = entity_leagues.reject{|i|i.nil?}
    self.average_league = non_nil_leagues.avg unless non_nil_leagues.empty?

    # And if all entities have a highest_league, close this match for further
    # postprocessing by setting its state to final.
    self.state = 1 unless entity_leagues.include?(nil)

    # http://sequel.rubyforge.org/rdoc/classes/Sequel/Model/InstanceMethods.html#method-i-save_changes
    save_changes
    
    invalidate_cache!
  end

  # Returns an ESDB::Match (dataset) that has been restricted to have the given identity, and with that identity
  # playing a certain race, against a certain race, or both.
  #
  # TODO use hash for parameters
  # 
  def self.for_identity_and_race(identity_id, race=nil, vs_race=nil)
    dataset = ESDB::Match.qualify.distinct
    dataset = dataset.inner_join(ESDB::Sc2::Match::Entity, {:match_id => :id}, {:table_alias => :me1})
    dataset = dataset.inner_join(ESDB::IdentityEntity, {:entity_id => :me1__id, :identity_id => identity_id}, {:table_alias => :ie1})

    if race
      dataset = dataset.where(:me1__race => race[0].downcase)
    end

    if vs_race
      dataset = dataset.inner_join(ESDB::Sc2::Match::Entity, {:match_id => :me1__match_id}, {:table_alias => :me2})
      dataset = dataset.where(~{:me1__team => :me2__team})
      dataset = dataset.where(:me2__race => vs_race[0].downcase)
    end

    dataset
  end

  # TODO: find a better name for this function
  # TODO use hash for parameters
  # TODO unify with for_identity_and_race
  #
  # Returns an ESDB::Match (dataset) that has been restricted to have the given race or matchup.
  #
  def self.for_race(race=nil, vs_race=nil)
    if race.present? && vs_race.present?
      matchups = [ ESDB::Sc2::Match::Matchup.matchup_id(race[0].downcase, vs_race[0].downcase) ]
    else
      race ||= vs_race
      matchups = ESDB::Sc2::Match::Matchup.singlerace_matchup_ids(race[0].downcase)
    end
    dataset = ESDB::Match
    dataset = dataset.inner_join(ESDB::Sc2::Match::Matchup, :match_id=>Sequel.qualify(ESDB::Match.table_name, 'id'))
    dataset = dataset.where(Sequel.qualify(ESDB::Sc2::Match::Matchup.table_name, :matchup) => matchups)
    dataset.qualify
  end

  # find the URL to show for this map.
  # priority:
  # 1 this match's map's image
  # 2 the image from any map with the same name as this match
  #
  # it is convoluted because:
  # * there are multiple Maps with the same name, and more such Maps may be added to our system _after_ we have POSTed images into the system
  # * matches that are solely from an s2gs don't have a Map at all, and only have Mapfacts.
  #
  # We could make things a little simpler by having a separate table
  #  that associates a mapname with an image.  Currently we are
  #  effectively using the Map table itself as that table.
  #
  def map_url
    if map.present? && map.image.present?
      return map.image.url
    end

    if map_name.present?
      mapWithImage = ESDB::Sc2::Map.where({:name => map_name}, ~{:image => nil}).first
      if mapWithImage.present?
        return mapWithImage.image.url
      end
    end
  end

  #
  # returns the name of the map this match was played on.
  # 
  # slightly convoluted because matches that are solely from an s2gs
  #  don't have a Map at all, and only have Mapfacts.
  # 
  def map_name
    if map.present?
      return map.name
    else
      if summaries[0].present? && summaries[0].mapfacts.present?
        return summaries[0].mapfacts.map_name
      end
    end
  end

  def uploaded_at
    if replays_count > 0
      return replays.first.uploaded_at
    elsif summaries_count > 0
      return summaries.first.processed_at
    end
  end

  def ended_at
    # TODO put game speed into matches table so that we dont assume
    # every game is played at Faster speed
    return nil if duration_seconds.blank?
    return played_at + duration_seconds / 1.4
  end

  # Serialize to Jbuilder
  def to_builder(options = {})
    builder = options[:builder] || jbuilder(options)

    builder.(self, :id, :ended_at, :winning_team, :category, :game_type, :average_league, :duration_seconds, :release_string,
                   :replays_count, :summaries_count, :expansion, :cobrand)
    builder.map_name(map_name)

    builder.map(map ? map.to_builder.attributes! : {}) if builder.filter.match.map?
    builder.map_url(map_url) if builder.filter.match.map_url?

    # TODO: see entity_summary.rb
    # builder.summaries(summaries.processed.all) {|builder, summary| summary.to_builder(builder)}

    builder.entities(entities) {|builder, entity| entity.to_builder(options.merge(builder: builder))} if builder.filter.match.entities?
    builder.replays(replays) {|builder, replay| replay.to_builder(options.merge(builder: builder))} if builder.filter.match.replays?

    # TODO add uploaded_at once replays have an uploaded_at !

    builder
  end

  def self.get_matches(params, current_provider)

        plain_matches_index = false
        raw_params = params.keys - ["filter", "route_info", "method", "path", "version"]
        if raw_params.length == 2 &&
            raw_params.include?('paginate') &&
            raw_params.include?('replay') &&
            params[:paginate] == false &&
            params[:replay] == true
          plain_matches_index = true
#          ESDB.log("a plain matches request. #{raw_params} #{raw_params.length} #{raw_params.include?('paginate')} #{raw_params.include?('replay')} #{params[:paginate]} #{params[:replay]}")
#        else
#          ESDB.log("not a plain matches request. #{raw_params} #{raw_params.length} #{raw_params.include?('paginate')} #{raw_params.include?('replay')} #{params[:paginate]} #{params[:replay]}")
        end

        # TODO API should support ordering by ended_at, which here
        # should turn into an SQL expression (since we dont have nor
        # need an ended_at column)

        _params = Hashie::Mash.new(params.reverse_merge({
          limit: 10,
          offset: 0,
          order: '_played_at',
        }.stringify_keys))
        params = _params

        # Default fields, if it's a blank object
        params[:filter] = '-graphs,match(-replays,-map,-map_url),entity(-summary,-minutes,-armies)' if params[:filter].is_a?(ApiFields::Blank)

        if params[:identity_id]
          if params[:race] || params[:vs_race]
            dataset = ESDB::Match.for_identity_and_race(params[:identity_id], params[:race], params[:vs_race])
          else
            dataset = Identity[params[:identity_id]].matches
          end
        else
          if params[:race] || params[:vs_race]
            dataset = ESDB::Match.for_race(params[:race], params[:vs_race])
          else
            dataset = ESDB::Match
          end
        end

        # Various filters that can be where'd directly
        [:game_type, :map_id, :average_league, :gateway, :category].each do |optional_filter|
          dataset = dataset.where(Sequel.qualify(ESDB::Match.table_name, optional_filter) => params[optional_filter]) if params[optional_filter]
        end

        if params[:category] == 'Ladder'
          dataset = dataset.where({Sequel.qualify(ESDB::Match.table_name, :vs_ai) => 0} | {Sequel.qualify(ESDB::Match.table_name, :vs_ai) => nil})

# 20130516 argh the ranked indicator is actually busted, we cant tell when people play Unranked matchmaking
#
#          dataset = dataset.where({Sequel.qualify(ESDB::Match.table_name, :ranked) => 1} | {Sequel.qualify(ESDB::Match.table_name, :ranked) => nil})
        end

        if params[:replay_after_dt]
          dataset = dataset.inner_join(:esdb_sc2_match_replays, :match_id => Sequel.qualify(ESDB::Match.table_name, 'id'))
          dataset = dataset.where(" unix_timestamp(uploaded_at) > ? ", params[:replay_after_dt])
        end

        if params[:sc2ranks]
          dataset = dataset.where(~{:gateway => 'xx'})
          dataset = dataset.order(Sequel.send('asc', 'uploaded_at'))
          params[:order] = nil
        end

        if params[:map_name]
          dataset = dataset.eager_graph(:map).where(:map__name => params[:map_name])
        end

        if params[:pack]
          dataset = dataset.inner_join(:esdb_match_pack, :match_id => Sequel.qualify(ESDB::Match.table_name, 'id'))
          dataset = dataset.inner_join(:esdb_pack, :pack_id => Sequel.qualify(:esdb_match_pack, 'pack_id'))
          dataset = dataset.where(Sequel.qualify(:esdb_pack, 'name') => params[:pack])
        end

        if params[:wcs]
          dataset = dataset.where("`esdb_matches`.`cobrand` = 1")
        end

        # Matches that have summaries, or replays
        dataset = dataset.where{replays_count > 0} if params[:replay]
        dataset = dataset.where{summaries_count > 0} if params[:summary]

        # Deleted matches are left out
        dataset = dataset.where("`esdb_matches`.`id` not in (select match_id from esdb_matches_deleted)")


        # Super-short matches are left out.  Less than two minutes just isnt worth showing anyone
        dataset = dataset.where("`esdb_matches`.`duration_seconds` > 120")

        if params[:one_wins] || params[:two_wins] || params[:unit_one] || params[:unit_two]
          dataset = dataset.inner_join(Sequel.as(:esdb_sc2_match_entities, :entity_one), :match_id => Sequel.qualify(ESDB::Match.table_name, 'id'))
          dataset = dataset.inner_join(Sequel.as(:esdb_sc2_match_entities, :entity_two), :match_id => Sequel.qualify(ESDB::Match.table_name, 'id'))
          dataset = dataset.where(~{:entity_one__team => :entity_two__team})

          if params[:race]
            dataset = dataset.where(:entity_one__race => params[:race][0].upcase)
          end
          if params[:vs_race]
            dataset = dataset.where(:entity_two__race => params[:vs_race][0].upcase)
          end
          if params[:one_wins]
            dataset = dataset.where(:entity_one__win => true)
          end
          if params[:two_wins]
            dataset = dataset.where(:entity_two__win => true)
          end
          if params[:unit_one]
            unitnum = ESDB::Sc2::unitNumber(params[:unit_one])
            dataset = dataset.where("entity_one.u#{unitnum} > 0")
            if params[:time_one]
              dataset = dataset.inner_join(Sequel.as(:esdb_sc2_match_replay_minutes, :mrm_one), :entity_id => :entity_one__id)
              dataset = dataset.where(:mrm_one__minute => params[:time_one])
              unit_one_count = 1
              if params[:unit_one_count]
                unit_one_count = params[:unit_one_count]
              end
              dataset = dataset.where("mrm_one.u#{unitnum} >= #{unit_one_count}")
            end
          end
          if params[:unit_two]
            unitnum = ESDB::Sc2::unitNumber(params[:unit_two])
            dataset = dataset.where("entity_two.u#{unitnum} > 0")
            if params[:time_two]
              dataset = dataset.inner_join(Sequel.as(:esdb_sc2_match_replay_minutes, :mrm_two), :entity_id => :entity_two__id)
              dataset = dataset.where(:mrm_two__minute => params[:time_two])
              unit_two_count = 1
              if params[:unit_two_count]
                unit_two_count = params[:unit_two_count]
              end
              dataset = dataset.where("mrm_two.u#{unitnum} >= #{unit_two_count}")
            end
          end
        end

        # Order
        if params[:order]
          field = params[:order][1..-1].strip
          direction = params[:order][0] == '-' ? 'asc' : 'desc'
          dataset = dataset.order(Sequel.send(direction, Sequel.qualify(dataset.model.table_name, field)))


          # dataset are matches. however stat_builder wants entities, in the opposite order.

          dataset_match_details = dataset.select(Sequel.qualify(ESDB::Match.table_name, 'id'),
                                                 Sequel.qualify(ESDB::Match.table_name, 'played_at'))
          dataset_entities = ESDB::Sc2::Match::Entity.inner_join(dataset_match_details, :id=>Sequel.qualify(ESDB::Sc2::Match::Entity.table_name, 'match_id'))

          # FIXME: the 't1' here happens to work, but is brittle -- likely to break as soon as anything else is changed about how we form queries.
          # need to make use of the unused_table_alias trick, perhaps?
          sb_dataset = dataset_entities.order(Sequel.send('asc', Sequel.qualify('t1', field)))
        end

        if params[:paginate]
          # Set the total after all filters have been applied, but before we limit
          params[:total] = dataset.count
        end

        # Use StatBuilder
        # with a dataset that has all our filters and entities ordered by the 
        # match order. See the order block.
        stat_builder = ESDB::StatBuilder.new(params.merge(dataset: sb_dataset))
        stat_builder.build!

        # Page overrides offset if present
        if params[:page]
          params[:offset] = (params[:page] - 1) * params[:limit]
        end
      

        # hack alert. the following query performs 10x better, saving
        # 450ms, compared to the naive query generated by Sequel.
        #
        # it's for the matches index, a page that people go to all the
        # time, but caching doesn't help because it's invalidated
        # every time a replay is uploaded.
        #
        if plain_matches_index
          # ESDB.log("plain matches index optimization")
          matches = ESDB::Match.with_sql("select * from (SELECT * FROM `esdb_matches` ORDER BY `esdb_matches`.`played_at` desc limit 500) the_matches where replays_count > 0 and id not in (select match_id from esdb_matches_deleted) ORDER BY (played_at + duration_seconds/1.4) DESC LIMIT 10 OFFSET 0")
          matches = matches.all

        elsif params[:identity_id]
          dataset = dataset.limit(params[:limit] || 10, params[:offset] || 0)
          matches = dataset.all
        
        else

          # the following evilness forces the played_at index to be
          # used, because mysql query optimizer is not so smart about
          # how to optimize queries that use limit and order by.
          #
          # http://www.mysqlperformanceblog.com/2007/02/16/using-index-for-order-by-vs-restricting-number-of-rows/
          #
          # unfortunately Sequel does not have a cleaner way to pass the hint through.
          #
          dataset = dataset.limit(params[:limit] || 10, params[:offset] || 0)
          dataset = dataset.qualify
          dataset_sql = dataset.sql
          if !params[:sc2ranks]
            dataset_sql = dataset_sql.sub("SELECT `esdb_matches`.* FROM `esdb_matches`", "SELECT `esdb_matches`.* FROM `esdb_matches` use index (played_at)")
          end

# Disabling this and the Matches Search feature for now because its not worth the system complexity.
# People werent excited enough about it.
#
#          if params[:game_type] == '1v1' && params[:replay]
#            dataset_sql = dataset_sql.gsub("`esdb_matches`", "`onevone_matches`")
#          end
          dataset = ESDB::Match.with_sql(dataset_sql)
          matches = dataset.all
        end

# not ready for primetime!
#
#          djstats: djstat_builder.to_hash

        if params[:sc2ranks]
          matchcount = matches.count
          if matchcount == 0
            ESDB.error("No matches retrieved for sc2ranks!")
          else
            ESDB.log("sc2ranks retrieved #{matchcount} matches")
          end
          Jbuilder.encode { |builder|
            builder.array!(matches) { |builder, match|
              builder.players(match.entities) { | builder, entity |
                if entity.sc2_identity
                  builder.name entity.sc2_identity.name
                  builder.bnet_id entity.sc2_identity.bnet_id
                  builder.region entity.sc2_identity.sc2ranks_region
                end
                builder.team entity.team
                builder.race ESDB::Sc2::SC2RANKS_RACE[entity.race]
              }
              builder.url "http://ggtracker.com/matches/#{match.id}"
              builder.map match.map_name
              builder.version match.release_string
              builder.game_time match.duration_seconds
              builder.gameplay_type match.game_type
              builder.upload_date match.replays.first.uploaded_at.strftime('%a, %e %b %Y %H:%M:%S %z') if match.replays.first && match.replays.first.uploaded_at
              if match.cobrand == 1
                builder.tournament "World Championship Series"
              end
            }
          }
        else
          Jbuilder.wrap({
                          params: params,
                          provider: current_provider,
                          stats: stat_builder.to_hash
                        }) do |builder|
            builder.array!(matches) {|builder, match|
              if match.id == nil || match.entities.length == 0
                raise "Bad matches index query result: #{match.to_s}, #{match.id}, #{match.entities.length}"
              end
              match.to_builder(builder: builder)
            }
          end
        end

  end
end
