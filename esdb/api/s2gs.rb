class ESDB::API
  namespace :s2gs do
    desc 'Display some identities with character codes'
    params do
    end
    get '/queue' do
      @identities = ESDB::Sc2::Identity.where(~{:character_code => nil}).order(Sequel.function(:RAND)).all
      @identities
    end

    desc 'Retrieve one or more identities off the s2gs queue'
    params do
      optional :gateway,  type: String, desc: 'Filter by gateway'
      optional :randoms,  type: Boolean, desc: 'Return random identities if legitimate work is unavailable'
    end
    get '/queue/pop' do
      queue_too_big = 3

      params[:limit] = params[:limit] ? params[:limit].to_i : 3

      # Set a timestamp in redis to the last pop that happened
      Resque.redis.set('mon:queue:pop', Time.now.to_i)

      # we can modify the good_gateways table when blizzard does
      # region maintenance, so that we're not mis-logging
      # s2gs-retrieval errors for identities just because the region
      # is currently down.
      good_gateways = DB[:esdb_good_gateways].collect{|h| h[:gateway]}

      if params[:gateway].present?
        if good_gateways.include?(params[:gateway])
          good_gateways = [params[:gateway]]
        else
          good_gateways = []
        end
      end

      #
      # S2GS pull priorities:
      # 1. any ggtracker user who has non-null s2gs_priority
      # 2. any ggtracker user who has been popped 1 to 3 times but we were unable to get any summaries
      # 3. any ggtracker user with a provider identity who has never been popped
      # 4. any ggtracker user who has uploaded a replay more recent than their last queue pop
      # 5. any ggtracker user with a provider identity who hasn't been popped in the past day
      #
      # IF THERE IS NO WORK IN THE PYTHON QUEUE:
      # 6. any player with a charcode, in order of when they've last been popped
      #
      # TODO rewrite this in Sequel so you can make it easier to refactor as needed

        s2gs_queries = ["""
SELECT si.id, si.gateway FROM `esdb_identities` pi, esdb_identity_identities ii, esdb_identities si
WHERE pi.`provider_id` IS NOT NULL AND (ii.right_id = pi.`id` AND ii.left_id = si.id) AND si.character_code is not null AND si.character_code > 0
AND si.name is not null
AND length(si.name) > 0
AND si.s2gs_priority IS NOT NULL
ORDER by si.s2gs_priority desc
""", """
SELECT si.id, si.gateway FROM `esdb_identities` pi, esdb_identity_identities ii, esdb_identities si
WHERE pi.`provider_id` IS NOT NULL AND (ii.right_id = pi.`id` AND ii.left_id = si.id) AND si.character_code is not null AND si.character_code > 0
AND si.name is not null
AND length(si.name) > 0
AND si.pops_since_summary_seen = 0
AND si.last_s2gsq_at IS NULL
""", """
SELECT si.id, si.gateway FROM `esdb_identities` pi, esdb_identity_identities ii, esdb_identities si
WHERE pi.`provider_id` IS NOT NULL AND (ii.right_id = pi.`id` AND ii.left_id = si.id) AND si.character_code is not null AND si.character_code > 0
AND si.name is not null
AND length(si.name) > 0
AND si.pops_since_summary_seen = 0
AND si.last_replay_uploaded_at - si.last_s2gsq_at > 0
ORDER by si.last_replay_uploaded_at asc
""", """
SELECT si.id, si.gateway FROM `esdb_identities` pi, esdb_identity_identities ii, esdb_identities si
WHERE pi.`provider_id` IS NOT NULL AND (ii.right_id = pi.`id` AND ii.left_id = si.id) AND si.character_code is not null AND si.character_code > 0
AND si.name is not null
AND length(si.name) > 0
AND si.last_replay_uploaded_at - si.last_s2gsq_at > 0
ORDER by si.last_replay_uploaded_at asc
""", """
SELECT si.id, si.gateway FROM `esdb_identities` pi, esdb_identity_identities ii, esdb_identities si
WHERE pi.`provider_id` IS NOT NULL AND (ii.right_id = pi.`id` AND ii.left_id = si.id) AND si.character_code is not null AND si.character_code > 0
AND si.name is not null
AND length(si.name) > 0
AND si.pops_since_summary_seen between 1 and 3
ORDER by si.last_replay_uploaded_at desc
"""]

      if params[:gateway] == 'xx'

        s2gs_queries = ["""
SELECT si.id, si.gateway FROM esdb_identities si
WHERE si.character_code is not null AND si.character_code > 0 AND si.gateway = 'xx'
AND si.name is not null
AND length(si.name) > 0
AND si.s2gs_priority IS NOT NULL
ORDER by si.s2gs_priority desc
""", """
SELECT si.id, si.gateway FROM esdb_identities si
WHERE si.character_code is not null AND si.character_code > 0 AND si.gateway = 'xx'
AND si.name is not null
AND si.pops_since_summary_seen = 0
AND length(si.name) > 0
AND si.last_s2gsq_at IS NULL
""", """
SELECT si.id, si.gateway FROM esdb_identities si
WHERE si.character_code is not null AND si.character_code > 0 AND si.gateway = 'xx'
AND si.name is not null
AND length(si.name) > 0
AND si.pops_since_summary_seen = 0
AND si.last_s2gsq_at IS NOT NULL
AND si.last_replay_uploaded_at - si.last_s2gsq_at > 0
ORDER by si.last_replay_uploaded_at - si.last_s2gsq_at desc
""", """
SELECT si.id, si.gateway FROM esdb_identities si
WHERE si.character_code is not null AND si.character_code > 0 AND si.gateway = 'xx'
AND si.name is not null
AND length(si.name) > 0
AND si.last_replay_uploaded_at - si.last_s2gsq_at > 0
ORDER by si.s2gs_priority desc
"""]
        
      end

       s2gs_queries.each{|query|
         idents_to_pull = DB.fetch(query)
         if idents_to_pull.count > 0
           idents_to_pull = idents_to_pull.limit(100).all.select{|ident| good_gateways.include?(ident[:gateway])}
           if idents_to_pull.count > 0
             first_ident_gateway = idents_to_pull.first[:gateway]

             ids_to_pull = idents_to_pull.select{|ident| ident[:gateway] == first_ident_gateway}.first(params[:limit]).collect{|ident| ident[:id]}
             @identities = Sc2::Identity.where({:id => ids_to_pull})

             break
           end
         end
       }

      if params[:randoms] && (!@identities || @identities.blank?)
        gateway_to_pull = good_gateways.sample
        league_to_pull = Array(0..6).sample

        # the following code makes us pull grandmasters and their leaguemates, which
        # lets do for a while to build up our library of GM stuff
        #
        #        gateway_to_pull = ['us','eu','kr'].sample
        #        league_to_pull = 6

        @identities = ESDB::Identity.where(~{:character_code => nil})
        @identities = @identities.where(~{:name => nil})
        @identities = @identities.where('length(name) > 0')
        @identities = @identities.where("character_code > 0")
        @identities = @identities.where(~{:last_summary_seen_at => nil})
        @identities = @identities.where({:gateway => gateway_to_pull,
                                         :current_league_1v1 => league_to_pull,
                                         :pops_since_summary_seen => 0})
        @identities = @identities.order(Sequel.lit('last_summary_seen_at is not null, last_summary_seen_at asc'))
        @identities = @identities.limit(params[:limit])
      end

      if @identities.present?
        @identities = @identities.limit(params[:limit])
        # Grab the response
        response = @identities.all

        # keep track of pop-related state for this identity
        response.each {|identity|
          identity.last_s2gsq_at = Time.now
          identity.pops_since_summary_seen = identity.pops_since_summary_seen + 1
          identity.save_changes
        }
      end

      if response && response.any?
        request.env['gg.apilog'] << "first identity is #{response.first.id} from gateway #{response.first.gateway}"
      else
        request.env['gg.apilog'] << "no identities to pop"
        error!('Not Found', 404)
      end

      response
    end

    desc 'Receive hashes'
    params do
      requires :hashes,  type: Array
      requires :gateway, type: String
      optional :source, type: String
    end
    post '/hashes' do

      NUM_IMPORTANT_SUMMARIES = Resque.redis.get('limits:summaries')
      if NUM_IMPORTANT_SUMMARIES.nil?
        NUM_IMPORTANT_SUMMARIES = 2
      end

      if params[:hashes] && params[:hashes].is_a?(Array) && !params[:hashes].empty?

        good_summaries = 0
        ggtracker_user = 0
        if params[:identity_id]
          identity = ESDB::Identity[params[:identity_id]]
          if params[:source] == 'self' && identity.ggtracker_linked?
            ggtracker_user = 1
          end
        else
          identity = nil
        end

        hashnum = 0

        # Create empty summaries for every new hash we encounter
        params[:hashes].each do |hash|
          summary = ESDB::Sc2::Match::Summary.find_or_create(:s2gs_hash => hash) {|s| 
            s.first_seen_at = Time.now
          }

          # Create does not receive the block given to find_or_create.
          # Update the summary:
          if summary && summary.id != 0 # for some reason, the above comes back with unsaved records?
            if !summary.failed?
              good_summaries = good_summaries + 1
              summary.gateway = params[:gateway] if params[:gateway]

              if params[:identity_id]
                summary.identity_id = params[:identity_id] if params[:source] && params[:source] == 'self'

                if identity
                  summary.league = identity.current_league_1v1
                end
              end
            
              summary.save_changes

              # Enqueue retrieval/parser for this hash unless processed
              if summary && !summary.processed?
                summary.enqueue!((ggtracker_user == 1) && (hashnum < NUM_IMPORTANT_SUMMARIES))
              end
              hashnum = hashnum + 1
            end
          else
            ESDB.logger.error("Could not create or retrieve s2gs hash: #{hash} (#{summary.inspect})")
          end

          # What happens next:
          #
          # esdb/esdb/games/sc2/match/summary.rb     Resque::Job.create('python', 'ggtracker.jobs.ParseSummary', {:hash => s2gs_hash})
          # ggpyjobs/ggtracker/jobs.py               summaryDB = sc2reader_to_esdb.processSummary(StringIO(s2gs_file.read()), self)
          # ggpyjobs/sc2parse/sc2reader_to_esdb.py   """main entry point for s2gs processing."""
        end

        if good_summaries > 0
          identity.last_summary_seen_at = Time.now
          identity.pops_since_summary_seen = 0
          identity.save_changes
        end
      end

      # We simply send an empty success, it's not being looked at right now
      # anyway.
      success!('')
    end
  end
end
