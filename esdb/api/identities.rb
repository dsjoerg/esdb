class ESDB::API
  resource :identities do
    #
    # find a single Identity based on given attributes or create
    # it if :create is true and none is found.
    #
    # also, rename the identity to whatever is given in the URL, because
    # this tends to be a trustworthy source.
    #
    desc 'Find or create an Identity'
    params do
      optional :force,    type: Boolean, desc: 'Force a scrape of the identity at critical priority'
      optional :create,   type: Boolean, desc: 'Create identity if not found (currently unused)'
    end
    get '/find' do
      create = params.delete(:create)
      # Strip Grape params
      attrs = params.reject!{|k,v| [:route_info, :method, :path, :version, :format].include?(k.to_sym)}.to_hash.symbolize_keys

      # identity = create ? ESDB::Identity.find_or_create(attrs) : ESDB::Identity.find(attrs)
      if attrs[:profile_url]
        # Catch BnetScraper exceptions here for now
        begin
          identity = ESDB::Identity.for_url(attrs[:profile_url]) || ESDB::Identity.from_url(attrs[:profile_url])
        rescue Exception => e
          error!(e.message)
        end
      else
        identity = ESDB::Identity.find_or_create(attrs)
      end

      # TODO: generic updates, or ..I'd rather have a real endpoint to POST to
      # for now, just set the character_code here.
      if params[:character_code]
        identity.character_code = params[:character_code] 
      end

      if attrs[:profile_url]
        bs = BnetScraper::Starcraft2::ProfileScraper.new(:url => attrs[:profile_url])
        identity.name = bs.name
        identity.name_valid_at = Time.now
        identity.name_source = 'ggtracker user'
        identity.save_changes
      end

      error!('Could not create or identify identity') if !identity

      # Make this a Sc2::Identity if it is identifiable to battle.net
      if identity.bnet_identifiable?
        begin
          identity.type = ESDB::Sc2::Identity 
          identity.save
          identity.invalidate_cache!
        rescue
          ESDB.logger.error("Could not set identity type on: #{identity.inspect}")
        end

        # identity.reload
        # Somehow, #reload won't re-instantiate properly anymore? Oh well..
        identity = Identity[identity.id]
      end


      # Now here is where it gets a little complicated, and this comment should
      # probably go elsewhere in documentation later on:
      #
      # In order to provide callbacks to every provider that is interested
      # in this identity (currently obviously only ourself, but soon enough
      # the MLG or others may need this) I am changing identities to this:
      #
      # Every Identity has_many other identities (identity_identities)
      # Typically, a provider identity will have one or many sc2 identities
      # and any sc2 identity might have multiple provider identities.
      #
      # This makes it very easy to identify the providers we will have to
      # inform about changes on any given identity.
      #
      # The important change that still has to be made (TODO!):
      # replays currently have many identities, among which there are both
      # provider and sc2 identities. I still have to decide if this can be made
      # to work or if we should switch back to a single identity_id that is
      # always the sc2 identity, through which we can identify the provider
      # identities (querying might become very difficult then).
      # This depends on whether we want to support a large number of providers.
      # Having 5 provider identities on a replay is not a problem, but having
      # a hundred might be.
      #
      # Also see notes on the join we do in Identity
      
      # Create a provider identity for the calling provider for this identity
      # if none exists (to receive callbacks for example)
      # TODO: opt out? control? Blank identity for now, find and document ways
      # to improve this (see identities endpoint for MLG hacks)
      if current_provider
        if !identity.provider_identity_for(current_provider)
          provider_identity = ESDB::Provider::Identity.create(:provider_id => current_provider.id)
          identity.add_identity(provider_identity)
        end
      end

      # Then queue a scrape with critical priority if we never scraped before
      # or a rescrape is requested to be forced.
      if identity.bnet_identifiable? && (!identity.last_scraped_at || params[:force])
        identity.enqueue!(:priority => :crit, :force => params[:force] ? true : false)
      end

      identity.to_builder.attributes!
    end

    # GET /identities

    desc 'Retrieve an Identity'
    params do
      optional :filter,     type: String,
        desc: 'The Param formerly known as the FieldsParam, filters output.'
    end
    get '/:id' do
      cache(bind: [[ESDB::Identity, params[:id]], {:stats => params[:stats]}]) do

        ESDB.log("cache miss for identities/:id, params=#{params.to_s}")

        identity = ESDB::Identity[params[:id]]
        
        error!('Not Found', 404) if !identity || identity.id.blank? || identity.blocked.present?
        
        builder = identity.to_builder(filter: params[:filter], provider: current_provider)
        data = builder.attributes!

        # Insert Stats
        if params[:stats]
          params[:source] = params[:id]
    
          # When given a source/identities, StatBuilder will include identity 
          # information.. we either remove ours above, or strip it for now.
          # TODO: if we leave it in StatBuilder, the above should be removed.

          # TODO: make StatBuilder gracefully die if invalid options are passed
          begin
            stat_builder = ESDB::StatBuilder.new(params)
          rescue
            # And for now, we'll be a little ambiguous on the error message
            error!('Parameters invalid')
          end

          data[:stats] = stat_builder.to_hash
          data[:stats].delete(:identity)
        end
  
        data.to_json

      end # cache
    end

    # TODO: some of the shorthands/aliases might be candidates for a rename.
    desc 'Retrieve identities'
    params do
      # Filters
      optional :type,       type: String, desc: 'Identity Type (shorthand "sc2" for Sc2::Identity)'
      optional :name,       type: String, desc: 'Filter identities that contain :name (case insensitive)'

      optional :current_highest_league, type: Integer, desc: 'Filter by highest league'
      optional :most_played_race, type: String, desc: 'Filter by most_played_race'
      optional :race,       type: String, desc: 'Shorthand for most_played_race'
      optional :most_played,  type: String, desc: 'Filter by most_played'
      optional :game_type,  type: String, desc: 'Alias for current_highest_type'
      optional :gateway,    type: String, desc: 'Filter by gateway'
      optional :bnet_id,    type: Integer, desc: 'Filter by bnet id'

      # Options
      optional :limit,      type: Integer, desc: 'Limit (Default: 10)'
      optional :page,       type: Integer, 
        desc: 'Instead of calculating the offset, you can pass limit (or leave it at the default) and a page instead'
      optional :order,      type: String, 
        desc: 'Field to order results by, preceded by a dash for ascending, underscore for descending'

      optional :filter,     type: String,
        desc: 'The Param formerly known as the FieldsParam, filters output.'
    end

    get '/' do
      cache(bind: [ESDB::Identity]) do

        ESDB.log("cache miss for identities/, params=#{params.to_s}")

        plain_identities_index = false

        raw_params = params.keys - ["filter", "route_info", "method", "path", "version", "page"]
        if raw_params.blank?
          plain_identities_index = true
        end

        dataset = ESDB::Sc2::Identity

        # Shortcuts!
        {game_type: :current_highest_type, race: :most_played_race}.each do |k,v|
          params[v] = params.delete(k) if params[k.to_sym] && params[k.to_sym].present?
          params[v] = params[v][0] if v == :most_played_race && params[v] && params[v].present?
        end

        # Default params, would like to have that in the params block..
        # We have reverse_merge!, but Hashie screws with it :(
        _params = Hashie::Mash.new(params.reverse_merge({
          :limit => 10,
          :offset => 0,
          :order => '_current_highest_league'
        }.stringify_keys))
        params = _params

        params[:filter] = 'identity(-profile_url)' if params[:filter].is_a?(ApiFields::Blank)

        if params[:name] && params[:name].present?
          dataset = dataset.where(Sequel.ilike(:name, "#{params[:name]}%"))
        end

        # Various filters that can be where'd directly
        [:current_highest_league, :most_played_race, :gateway, :current_highest_type, :bnet_id].each do |optional_filter|
          dataset = dataset.where(optional_filter => params[optional_filter]) if params[optional_filter]
        end

        # Order
        # TODO: refactor, move away, beautify!
        # FIXME: name can be nil, bring about default filtering that excludes all
        # unscraped, empty, unready, etc. identities please.
        if params[:order]
          fieldname = params[:order][1..-1].strip
          direction = params[:order][0] == '-' ? 'asc' : 'desc'
          field = Sequel.qualify(dataset.model.table_name, fieldname)
          dataset = dataset.order(Sequel.send(direction, field))
          if (fieldname == 'current_highest_league')
            secondary_field = Sequel.qualify(dataset.model.table_name, 'current_highest_leaguerank')
            other_direction = params[:order][0] == '-' ? 'desc' : 'asc'
            dataset = dataset.order(Sequel.send(direction, field), Sequel.send(other_direction, secondary_field))
            dataset = dataset.exclude(:current_highest_league => nil).exclude(:current_highest_leaguerank => nil) unless params.include?(:name)
          end
        end

        if plain_identities_index
          dataset = ESDB::Identity.with_sql("""
select si.*
FROM esdb_identities pi, esdb_identity_identities ii, esdb_identities si
WHERE pi.`provider_id` IS NOT NULL AND (ii.right_id = pi.`id` AND ii.left_id = si.id)
and si.last_replay_played_at > (now() - interval 14 day)
and si.matches_count > 30
order by si.current_league_1v1 desc, si.current_rank_1v1 asc
""")
        end

        # Page overrides offset if present
        if params[:page]
          params[:offset] = (params[:page] - 1) * params[:limit]
        end

        identities = dataset.limit(params[:limit] || 10, params[:offset] || 0).all

        Jbuilder.wrap(params: params) do |builder|
          builder.array!(identities) {|builder, identity| identity.to_builder(
            builder: builder, 
            filter: params[:filter], 
            provider: current_provider
          )}
        end

      end # cache
    end # get '/' do

    desc 'Receive a Char Code for an XX gateway identity'
    params do
      requires :charcode, type: Integer, desc: 'Character Code'
      requires :user_id, type: Integer, desc: 'User supplying the Character Code'
    end
    post '/:id/charcode' do
      identity = ESDB::Identity[params[:id]]
      error!('Not Found', 404) if !identity || identity.id.blank? || identity.gateway != 'xx'
      error!('Not valid', 400) if !params[:user_id] || params[:user_id] == 0

      identity.character_code = params[:charcode]
      identity.save

      ESDB.warn("Updated character code for #{identity.name} (#{identity.id}) to #{params[:charcode]} at the behest of ggtracker user #{params[:user_id]}")

      success!('')
    end # post '/:id/charcode' do


    post ':id/destroy_all_matches' do

      if @provider  # access_token must be provided, see esdb/api.rb
        Resque::Job.create('replays-low', 'ESDB::Jobs::Sc2::Identity::DeleteAllMatches', {:identity_id => params[:id]})
        success!({})
      else
        ESDB.error("destroy_all_matches! attempted but access_token unrecognized.")
      end
    end

  end # resource :identities do
end # ESDB::API
