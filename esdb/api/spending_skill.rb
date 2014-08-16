class ESDB::API
  resource :spending_skill do

    desc 'Get spending skill ranges'

    params do
      requires :race, type: String, desc: 'P T or Z'
      requires :gateway, type: String, desc: 'us or eu'
    end

    get '/:gateway/:race' do
      cache do
        # TODO make a version of get_sq_skill_table that doesnt cache,
        # so that we can clear the cache without restarting
        ist = ESDB::Match::EntitySummary.get_sq_skill_table

        # tolerate race 'protoss' and gateway 'am'
        params[:race] = params[:race][0].upcase
        if params[:gateway] == 'am'
          params[:gateway] = 'us'
        end      

        result = {}
        totalgames = 0
        0.upto(6).each { |league|
          leagueSQ = []
          leagueCounts = []
          5.upto(29).each { |minutes|
            sq_stats = ist[params[:gateway]][minutes][params[:race]][league]
            if sq_stats.present?
              leagueSQ << sq_stats[0]
              leagueCounts << sq_stats[1]
              totalgames = totalgames + sq_stats[1]
            else
              leagueSQ << nil
              leagueCounts << 0
            end
          }
          result[league] = leagueSQ
          result["counts#{league}"] = leagueCounts
        }
        result["totalgames"] = totalgames
        result.to_json
      end
    end
  end
end
