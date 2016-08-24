class ESDB::Sc2
  class Identity < ESDB::Identity
    module Sc2Ranks
      class InvalidProfileError < Exception; end
      class NotAvailableNowError < Exception; end
      class BadResponseCodeError < Exception; end
    end

    # To be identifiable to Battle.net, we need the name. 
    # Really hate the syntax.
    subset :bnet_identifiable, ~{bnet_id: nil}, ~{subregion: nil}, ~{gateway: nil}, ~{name: nil}, ~{name: ''}

    # State Machinery.
    # TODO: proper transitions

    state_machine :state, :initial => :new do
      state :valid, :invalid, :error
    end

    LEAGUES = [:bronze, :silver, :gold, :platinum, :diamond, :master, :grandmaster]

    # maps blizzard replay's gateway/subregion to bnet_scraper's region codes.
    # see https://github.com/ggtracker/bnet_scraper/blob/regions/lib/bnet_scraper/starcraft2.rb
    # which has essentially the reverse mapping.
    BNET_SCRAPER_REGION = {
      'us'=> {
        1=> 'na',
        2=> 'la',
      },
      'eu'=> {
        1=> 'eu',
        2=> 'ru',
      },
      'kr'=> {
        1=> 'kr',
        2=> 'tw',
      },
      'tw'=> {
        1=> 'kr',
        2=> 'tw',
      },
      'cn'=> {
        1=> 'cn',
      },
      'sea'=> {
        1=> 'sea',
      },
      'xx'=> {
        1=> 'xx',
      }
    }

    # maps blizzard replay's gateway/subregion to sc2ranks region codes.
    # note that http://sc2ranks.com/api is full of lies.
    #
    # http://stackoverflow.com/questions/4157399/how-do-i-copy-a-hash-in-ruby
    SC2RANKS_REGION = Marshal.load(Marshal.dump(BNET_SCRAPER_REGION))
    SC2RANKS_REGION['us'][1] = 'us'
    SC2RANKS_REGION['tw'][2] = 'kr'
    SC2RANKS_REGION['eu'][2] = 'ru'

    def validate
      validates_presence [:bnet_id, :subregion, :gateway]
      validates_unique [:bnet_id, :subregion, :gateway]
    end

    #
    # identity has the following fields related to league ranking:
    #
    # current_league_[1v1,2v2,3v3,4v4]: the current highest league for
    #  that gametype.  note that for 2v2, 3v3, 4v4, the player may be
    #  on many "teams", and for each team they have a league. for
    #  example, current_league_4v4 is the player's highest league
    #  among all their 4v4 teams.
    #
    # current_rank_[1v1,2v2,3v3,4v4]: the current highest rank for the
    #  highest league for that gametype.
    #
    # current_highest_type: in which gametype (1v1, 2v2, etc) does
    #  this player have the highest league? in a tie, the gametype
    #  with fewer players wins.
    # current_highest_league: the league for the current_highest_type.
    # current_highest_leaguerank: the rank for the current_highest_type.
    #
    # most_played and most_played_race: From the battle.net profile
    #  front page, the "Most Played Mode" and the "Most Played Race".
    #  Not available from sc2ranks! Don't be fooled! Do not try to
    #  fake it!
    #
    #
    # highest_team_league and highest_league: Marian says "The highest
    #  league refers to the highest league FINISH in past
    #  seasons. Naming is confusing here. Current league may be
    #  higher."
    #
    # TODO: FULLY REMOVE THESE FIELDS:
    # highest_league_[1v1,2v2,3v3,4v4]: the highest-EVER league for
    #  that gametype, since we started scraping this profile.
    # average_league: the average of all columns containing the word
    #  "league" in them, with non-nil values.  Do not use.
    # highest_league: the max of all columns that match league, except not *_rank and 
    #  average_league and all nil values.  Do not use.
    # highest_league_rank: not sure exactly what this was supposed to
    #  be. Do not use.
    #
    #

    def full_accumulate!

      # only do a full_accumulate once per day, because
      # full_accumulate is not that important relative to the load it
      # puts on the DB.  it just keeps our stats in sync in case
      # multiple replays are uploaded.
      if last_stats_refresh.present? && (Time.now < (last_stats_refresh + (3600.0 * 24.0)))
        return
      end

      teh_sql = """
update esdb_identities as ident
left join (
select ie.identity_id, count(*) as thecount, avg(apm) as avg_apm, avg(wpm) as avg_wpm, sum(duration_seconds) as seconds_played_sum
from esdb_matches m, esdb_sc2_match_entities me, esdb_identity_entities ie
where m.id = me.match_id and
     ie.entity_id = me.`id` and
     ie.identity_id = #{id} and replays_count > 0
     group by ie.identity_id
 ) as summinfo on ident.id = summinfo.identity_id
set ident.matches_count = summinfo.thecount,
    ident.seconds_played_sum = summinfo.seconds_played_sum,
    ident.avg_apm = summinfo.avg_apm,
    ident.avg_wpm = summinfo.avg_wpm,
    ident.last_stats_refresh = now()
where ident.id = #{id}
"""

      DB << teh_sql

    end

    # In the spirit of Match#postprocess!, this sets highest_ and average_
    # leagues for the identity, among other things.
    #
    # This is called by the Scrape job
    #
    # TODO rename to after_scrape!
    #
    def postscrape!

      # dont bother with this for AI identities, whats the point
      if bnet_id == 0
        return
      end

      # Set highest_league for all entities that do not have one set.
      # TODO: this is where my proposed timeout would come in - only set it
      # if scraped within the past N days, close them up otherwise?
      entities.where(:highest_league => nil).update(:highest_league => current_highest_league)

      # Update highest_league_gametype for all entities where needed
      entities.where(:highest_league_gametype => nil).all.each do |entity|
        if current_highest_type.present?
          entity.highest_league_gametype = current_highest_type[0].to_i unless !entity.match
          entity.save_changes
        end
      end

      # After postprocessing all entities, postprocess all unfinalized 
      # matches.
      matches.unfinalized.all.each do |match|
        match.postprocess!
      end

      save_changes
      invalidate_cache!
    end

    # Return a BnetScraper object for this Identity, if we have
    #  sufficient info to scrape from battle.net
    def bnet_scraper

      # Player 2 is not a valid identity that we want to scrape.  Nor are test gateways
      if (bnet_id == 0 || subregion == 0 || gateway == 'xx')
#        ESDB.warn("Not going to scrape identity #{id} because of zero bnet_id (#{bnet_id}) or subregion (#{subregion})")
        return nil
      end

      if !has_a_name?
        return nil
      end

      @bnet_scraper ||= BnetScraper::Starcraft2::ProfileScraper.new(
        bnet_id: bnet_id, 
        name: URI.encode(name), 
        gateway: gateway,
        subregion: subregion
      )

      if (!@bnet_scraper)
        ESDB.warn("bnet_scraper is nil for identity #{id}! bnet_id=#{bnet_id}, name=#{name}, gateway=#{gateway}, subregion=#{subregion}")
      end

      @bnet_scraper
    end

    # Queues a job to call #scrape! asynchronously.
    # Currently, only the scrape job itself will queue with :sc2ranks as a
    # source, as fallback.
    #
    # This writes scrape_job_id and only allows the job to be queued once.
    #
    # @param [Symbol] source Source of profile information, `:sc2ranks` or 
    # `:bnet` - defaults to `:bnet`
    # @return [String] Job id
    def enqueue!(options = {})
      # Backward compat
      options = {:source => options} if options.is_a?(Symbol)

      options.reverse_merge!({
        :source => nil,
        :priority => nil,
        :force => false
      })

      return false if gateway == 'xx'
      return false if !options[:force] && 
        (enqueued? || last_scraped_at.to_i >= 24.hours.ago.to_i)

      klass = ESDB::Jobs::Sc2::Identity::Scrape
      queue = options[:priority] ? "#{Resque.queue_from_class(klass)}-#{options[:priority].downcase}" : Resque.queue_from_class(klass)
      self.scrape_job_id = klass.enqueue_to(queue, klass, options.merge({
        :identity_id => self.id
      }))

      save_changes
    end

    # Is the identity currently queued for processing?
    def enqueued?(_job = :scrape)
      return false if !scrape_job_id || scrape_job_id.empty?

      case _job
      when :scrape
        # TODO: we can patch resque-status easily to support resque-loner,
        # see lib/patch/resque-status.rb
        # ESDB::Jobs::Sc2::Identity::Scrape.enqueued?({:identity_id => self.id, :source => :bnet}) ||
        # ESDB::Jobs::Sc2::Identity::Scrape.enqueued?({:identity_id => self.id, :source => :sc2ranks})
        if status = Resque::Plugins::Status::Hash.get(scrape_job_id)
          if status['status'] == 'completed'
            ESDB.log("Scrape job loiters in identity #{id} with status #{status['status']}")
          else
            return true
          end
        end
      else
        false
      end
    end

    # proper english?
    def queued?(*args)
      enqueued?(*args)
    end

    def job(_job = :scrap)
      # Possible via resque-loner unique_job_queue_key, not needed yet though
    end

    # Scrapes account data off sc2ranks and battle.net, or enqueues a job to
    # do it asynchronously.
    #
    # This defaults to battle.net, we can fall back to sc2ranks if necessary,
    # especially on bulk updates. Reasons being obvious: sc2ranks is not 
    # updated in realtime and provides less data ..but it doesn't go into
    # maintenance regularly, so we're not entirely blocked by Blizzard's 
    # (frequent and often long) downtimes.
    # TODO: add checks and requeue for battle.net scraping.
    #
    # @param [Symbol] source Source of profile information, `:sc2ranks` or 
    # `:bnet` - defaults to `:bnet`
    # @param [Boolean] enqueue Enqueue a job to scrape asynchronously
    # @param [Boolean] redirect Attempt redirects to other services (e.g. 
    # scrape :bnet after successfully scraping :sc2ranks), or just stop.
    # @return [Boolean, String] Success or job id

    # Because the _scrape! method has grown rather large, we funnel it through
    # this method to catch exceptions and update state and status properly.
    def scrape!(*args)
      begin
        result = _scrape!(*args)
      rescue Exception => e
        if e.is_a?(BnetScraper::InvalidProfileError) || e.is_a?(Sc2Ranks::InvalidProfileError)
          update(:state => 'invalid', :status => e.inspect)
        elsif e.is_a?(Sc2Ranks::NotAvailableNowError)
          update(:state => 'unavailable', :status => e.inspect)
        elsif e.is_a?(Sc2Ranks::BadResponseCodeError)
          update(:state => 'responsecode', :status => e.inspect)
        else
          # the above problems are not worth bothering DJ about
          # however a totally unknown exception is worth looking at
          update(:state => 'craziness', :status => e.inspect)
          raise e
        end
      end
      
      # If last_scraped_at has not been set or _scrape! returned false we
      # must assume an error (TODO: raise errors!)
      if !result || !scraped?
        update(:state => 'mystery_err', :status => nil)
        return false
      end
      
      update(:state => 'valid', :status => nil)

      return true
    end

    def compute_most_played_race

      return nil if (bnet_scraper.career_terran_wins.blank? ||
                     bnet_scraper.career_protoss_wins.blank? ||
                     bnet_scraper.career_zerg_wins.blank?)

      num_most_played = 0
      result = nil

      if bnet_scraper.career_terran_wins.to_i > num_most_played
        num_most_played = bnet_scraper.career_terran_wins.to_i
        result = 't'
      end
      if bnet_scraper.career_protoss_wins.to_i > num_most_played
        num_most_played = bnet_scraper.career_protoss_wins.to_i
        result = 'p'
      end
      if bnet_scraper.career_zerg_wins.to_i > num_most_played
        num_most_played = bnet_scraper.career_zerg_wins.to_i
        result = 'z'
      end

      return result
    end

    #
    # sets a bunch of league-related fields on the identity.
    #
    # types: a list of ["1v1", "2v2", "3v3", "4v4"]
    # current_highest: a map of type=>leaguenum
    # current_highest_rank: a map of type=>highest rank for the highest league in that type
    #
    def set_league_info(types, current_highest, current_highest_rank)
      if current_highest['1v1'] > -1 &&
         self[:current_league_1v1].present? &&     
         current_highest['1v1'] != self[:current_league_1v1]
      end
      
      types.each { |type|
        if current_highest[type] > -1
          self["current_league_#{type}".to_sym] = current_highest[type]
          self["current_rank_#{type}".to_sym] = current_highest_rank[type]
        end
      }
      if current_highest.values.max > -1
        self[:current_highest_type] = current_highest.select{|type, league| league == current_highest.values.max}.keys.min
        self[:current_highest_league] = current_highest.values.max
        self[:current_highest_leaguerank] = self["current_rank_#{self[:current_highest_type]}".to_sym]
      end
    end

    # scrape no more than once per second
    def we_can_scrape_sc2ranks?
      return false
    end

    def _scrape!(source = nil, enqueue = false, redirect = true, ratelimit = true)
      return self.enqueue!(source) if enqueue
      return nil if gateway == 'xx'

      source = :bnet

      case source.to_s.downcase.to_sym
      when :bnet
        raise BnetScraper::InvalidProfileError, "source is :bnet but bnet_scraper is false" if !bnet_scraper

        sleep 0.1
        data = bnet_scraper.scrape
        
        # Stow the raw returned data away for later use
        ESDB::Blob.create(:data => data.to_s, :created_at => Time.now, :source => profile_url)

        self.set_all({
          :achievement_points => bnet_scraper.achievement_points,
          :season_games       => bnet_scraper.games_this_season,
          :career_games       => bnet_scraper.career_games,
          :most_played        => bnet_scraper.most_played,
          :portrait           => bnet_scraper.portrait,
          
          :most_played_race   => compute_most_played_race,
          
          :last_scraped_at    => Time.now,
          :name_valid_at      => Time.now,
          :name_source        => 'battle.net',

          # TODO: rename? The highest league refers to the highest league 
          # FINISH in past seasons. Naming is confusing here. Current league
          # may be higher.
          :highest_league     => league_index(bnet_scraper.highest_solo_league),
          :highest_team_league => league_index(bnet_scraper.highest_team_league)
        })

        current_highest = {}
        current_highest_rank = {}
        types = [1,2,3,4].collect {|num| num.to_s + "v" + num.to_s}
        types.each { |type| current_highest[type] = -1 }

        # Parse out current textual representation from battle.net
        # TODO: decide to ignore it or give bnet_scraper multilingual 
        # capabilities :)
        bnet_scraper.leagues.each do |league|

          # TODO: add this parser to bnet_scraper instead
          type, random, league, _, rank = league[:name].scan(/(\dv\d)\ (Random\ )*(\w+)\ (<span>Rank (\d+))*/).flatten

          if type && league && types.include?(type)
            if current_highest[type] < league_index(league)
              current_highest[type] = league_index(league)
              current_highest_rank[type] = rank.to_i
            end
            if (current_highest[type] == league_index(league) &&
                current_highest_rank[type] > rank.to_i)
              current_highest_rank[type] = rank.to_i
            end
          end
        end

        set_league_info(types, current_highest, current_highest_rank)

        save
      else
        raise ":source unrecognized! wtf is #{source.to_s.downcase}"
      end

      return true
    end

    # Has it ever been scraped?
    def scraped?
      last_scraped_at ? true : false
    end

    def league_index(league_name)
      LEAGUES.index(league_name.to_s.downcase.to_sym)
    end

    def profile_url
      bnet_scraper ? bnet_scraper.profile_url : nil
    end
    
    # DEPRECATED
    # use Identity.for_url and Identity.from_url to construct and find 
    # identities for and from an URL.
    def profile_url=(*args)
      raise "DEPRECATED: the profile_url attribute is deprecated. Use Identity.from_url"
    end
    
    # Compute what "region" sc2ranks wants us to put in our request to them.
    def sc2ranks_region
      SC2RANKS_REGION[gateway][subregion]
    end

    def sc2ranks_url
      return nil if gateway == 'xx'
      return nil if (!bnet_id || !sc2ranks_region)
      "http://sc2ranks.com/api/base/teams/#{sc2ranks_region}/#{name}!#{bnet_id}?appKey=ggtracker.com"
    end

    def has_a_name?
      if !values[:name] || values[:name].blank?
        return false
      end
      return true
    end

    def name
      if values[:name].blank?
        'Unknown'
      else
        values[:name]
      end
    end

    def hours_played
      seconds_played_sum.to_f / 3600.0
    end

    def destroy_all_matches!
      Garner::Cache::ObjectIdentity.invalidate(ESDB::Match)
      Garner::Cache::ObjectIdentity.invalidate(ESDB::Identity, self.id)

      matches.each { |match|
        match.replays.destroy
        match.summaries.destroy
        match.destroy
      }
      nil
    end

    # Serialize to Jbuilder
    def to_builder(options = {})
      builder = options[:builder] || jbuilder(options)

      builder.(self, :id, :type, :name, :provider_id, :provider_ident, 
              :gateway, :subregion, :bnet_id, :matches_count, :hours_played)

      builder.(self, :profile_url) if builder.filter.identity.profile_url?
      builder.(self, :character_code) if builder.provider && builder.provider.ggtracker?
      
      # Battle.net Attributes
      builder.(self, :most_played_race,
              :current_highest_type, :current_highest_league,
              :current_highest_leaguerank,
              :current_league_1v1, :current_rank_1v1,
              :current_league_2v2, :current_rank_2v2,
              :current_league_3v3, :current_rank_3v3,
              :current_league_4v4, :current_rank_4v4,
              :achievement_points, :season_games, :career_games, :portrait)

      # Note: I'm calling last_scraped_at updated_at for the public interface.
      # a much friendlier term, although not entirely accurate.
      # We might want to track a real updated_at instead. (TODO?)
      builder.updated_at last_scraped_at
      builder.queued queued?

      # most_played -> most_played_gametype for consistency?
      builder.most_played_gametype most_played

      # Statistical Attributes
      # Even if we're "caching" these attributes elsewhere, we still output
      # them in "stats" properly.
      # TODO: please give me deep_stringify_keys, jesus.
      builder.stats({
        'apm' => {'avg' => avg_apm},
        'wpm' => {'avg' => avg_wpm},
      })
      
      builder
    end
  end
end
