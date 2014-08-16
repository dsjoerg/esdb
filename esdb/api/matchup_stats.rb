class ESDB::API
  resource :matchup_stats do

    desc 'Get stats about matchups'

    params do
      requires :timeperiod, type: String, desc: 'patch_153 or patch_143'
    end

    get '/:timeperiod' do
      cache do

        ESDB.log("cache miss for matchup stats")
#        puts "yo cache miss"

        if params[:timeperiod] == 'patch_153'
          begin_date = '2012-12-04'
        elsif params[:timeperiod] == 'patch_143'
          begin_date = '2012-05-10'
          end_date = '2012-12-04'
        end
  
        result = {}
  
        conds = ""
        if begin_date.present?
          conds = conds + " and m.played_at > '#{begin_date}' "
        end
        if end_date.present?
          conds = conds + " and m.played_at < '#{end_date}' "
        end  
 
        query = """
select m.average_league, e1.race as race_1, e2.race as race_2,
       floor(1000.0 * sum(e1.win)/count(*))/10.0 as win1,
       floor(1000.0 * sum(e2.win)/count(*))/10.0 as win2,
       count(*) as count
from
esdb_matches m,
esdb_sc2_match_entities e1,
esdb_sc2_match_entities e2
where m.category = 'Ladder'
  and m.game_type = '1v1'
  and m.duration_seconds > 180
  and e1.race < e2.race
  #{conds}
  and e1.match_id = m.id
  and e2.match_id = m.id
  and average_league is not null
group by m.average_league, e1.race, e2.race
order by m.average_league, e1.race, e2.race
"""

        matchup_stats = {}
        DB.fetch(query) do |row|

            # canonicalize the position of first and second race
            if row[:race_1] == 'T' || row[:race_2] == 'T'
              first_race = row[:race_2]
              second_race = row[:race_1]
            else
              first_race = row[:race_1]
              second_race = row[:race_2]
            end
            matchup = "#{first_race}v#{second_race}"

            rowstat = {}
            rowstat[row[:race_1]] = row[:win1]
            rowstat[row[:race_2]] = row[:win2]
            rowstat[:num_matches] = row[:count]
            matchup_stats[matchup] ||= {}
            matchup_stats[matchup][row[:average_league]] = rowstat

            if (row[:win1].blank? || row[:win2].blank? || row[:count].blank? || row[:average_league].blank?)
              raise "Bad matchup query result: #{row.to_s}"
            end
        end   # DB.fetch

          ['TvP','ZvT','PvZ'].each {|matchup|
            if matchup_stats[matchup].size != 7
              raise "Only had #{matchup_stats[matchup].size} leagues for #{matchup}"
            end
          }

        if matchup_stats.size != 3
          raise "Bad matchup API call, matchup_stats.size == #{matchup_stats.size}"
        end
        matchup_stats["now"] = Time.now
  
        matchup_stats.to_json
      end  # cache do
    end  # get '/:timeperiod' do
  end  # resource :matchup_stats do
end  # class ESDB::API
