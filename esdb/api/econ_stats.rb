class ESDB::API
  resource :econ_stats do

    desc 'Get economy stats'
    # result is a map of matchup ('PvZ', etc)
    # to a map of league to the stats for that matchup and league.
    get '/' do

      # used to have Garner here, but it was too hard to use
      # correctly, in particular for invalidation with the semantics
      # we need
      jsonresult = Resque.redis.get('econ_stats')

      if jsonresult.blank?
        ESDB.log("cache miss for econ stats")
        result = {}
        query = "select * from replays_econ_stat"
        DB.fetch(query) do |row|
          key = row[:race] + 'v' + row[:vs_race]
          result[key] ||= {}
          result[key][row[:highest_league]] = row
        end
        jsonresult = result.to_json
        Resque.redis.set('econ_stats', jsonresult)
      end

      jsonresult

    end  # get '/' do


    desc 'Get TheStaircase saturation benchmarks'
    # result is a map of league and matchup ('3PvZ', etc)
    # to a map of the relevant econ benchmarks for TheStaircase
    get '/staircase' do

      ESDB::Sc2::Match::Entity.saturation_skill_benchmarks_json

    end  # get '/staircase' do
  end  # resource :econ_stats do
end  # class ESDB::API
