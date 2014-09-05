require 'csv'

N = 1000000
PLAYDATE = '2014-08-01'


# computes a preconfigured set of stats

class ESDB::ScoutBuilder

  def self.do_it()

    header_row = ['match_id', 'race', 'win', 'chosen_race', 'apm', 'action_latency_real_seconds', 'spending_skill', 'race_macro']
    [1,2,3].each {|benchmark|
      header_row << 'mineral_sat_' + benchmark.to_s
      header_row << 'gas_sat_' + benchmark.to_s
      header_row << 'worker22x_' + benchmark.to_s
    }
    [2,3].each {|benchmark|
      header_row << 'miningbase_' + benchmark.to_s
    }
    [4,5,6,7,8,9,10,12,14,16,18,20,25,30].each {|minute|
      header_row << 'as' + minute.to_s
      header_row << 'w' + minute.to_s
    }

    CSV.open('/tmp/ents.csv', 'wb') { |csv|
      csv << header_row
      
      DB.fetch("""
select e.match_id, e.race, e.win, e.chosen_race, e.apm, e.spending_skill, e.race_macro, e.action_latency_real_seconds, ees.miningbase_2, ees.miningbase_3,
ees.mineral_saturation_1, ees.gas_saturation_1, ees.worker22x_1,
ees.mineral_saturation_2, ees.gas_saturation_2, ees.worker22x_2,
ees.mineral_saturation_3, ees.gas_saturation_3, ees.worker22x_3,
mrm4.armystrength as4, mrm4.u0 w4,
mrm5.armystrength as5, mrm5.u0 w5,
mrm6.armystrength as6, mrm6.u0 w6,
mrm7.armystrength as7, mrm7.u0 w7,
mrm8.armystrength as8, mrm8.u0 w8,
mrm9.armystrength as9, mrm9.u0 w9,
mrm10.armystrength as10, mrm10.u0 w10,
mrm12.armystrength as12, mrm12.u0 w12,
mrm14.armystrength as14, mrm14.u0 w14,
mrm16.armystrength as16, mrm16.u0 w16,
mrm18.armystrength as18, mrm18.u0 w18,
mrm20.armystrength as20, mrm20.u0 w20,
mrm25.armystrength as25, mrm25.u0 w25,
mrm30.armystrength as30, mrm30.u0 w30
from   
( select id, game_type, category, vs_ai, expansion from esdb_matches where played_at > '#{PLAYDATE}' ) rm,
esdb_entity_stats ees, esdb_sc2_match_entities e
left join  esdb_sc2_match_replay_minutes mrm4 on e.id = mrm4.entity_id  and mrm4.minute = 4 
left join  esdb_sc2_match_replay_minutes mrm5 on e.id = mrm5.entity_id  and mrm5.minute = 5 
left join  esdb_sc2_match_replay_minutes mrm6 on e.id = mrm6.entity_id  and mrm6.minute = 6 
left join  esdb_sc2_match_replay_minutes mrm7 on e.id = mrm7.entity_id  and mrm7.minute = 7 
left join  esdb_sc2_match_replay_minutes mrm8 on e.id = mrm8.entity_id  and mrm8.minute = 8 
left join  esdb_sc2_match_replay_minutes mrm9 on e.id = mrm9.entity_id  and mrm9.minute = 9 
left join  esdb_sc2_match_replay_minutes mrm10 on e.id = mrm10.entity_id  and mrm10.minute = 10 
left join  esdb_sc2_match_replay_minutes mrm12 on e.id = mrm12.entity_id  and mrm12.minute = 12 
left join  esdb_sc2_match_replay_minutes mrm14 on e.id = mrm14.entity_id  and mrm14.minute = 14 
left join  esdb_sc2_match_replay_minutes mrm16 on e.id = mrm16.entity_id  and mrm16.minute = 16 
left join  esdb_sc2_match_replay_minutes mrm18 on e.id = mrm18.entity_id  and mrm18.minute = 18 
left join  esdb_sc2_match_replay_minutes mrm20 on e.id = mrm20.entity_id  and mrm20.minute = 20 
left join  esdb_sc2_match_replay_minutes mrm25 on e.id = mrm25.entity_id  and mrm25.minute = 25 
left join  esdb_sc2_match_replay_minutes mrm30 on e.id = mrm30.entity_id  and mrm30.minute = 30 
where e.match_id = rm.id and
      ees.entity_id = e.id and
      rm.game_type = '1v1' and
      rm.category = 'Ladder' and
      rm.vs_ai = 0 and
      rm.expansion = 1
  limit #{N * 2}
""") {|ent|
        csv_row = [ent[:match_id], ent[:race], ent[:win], ent[:chosen_race], ent[:apm].to_i,
                   ent[:action_latency_real_seconds].round(3),
                   ent[:spending_skill].round(1),
                   ent[:race_macro].to_i]
        [1,2,3].each {|benchmark|
          csv_row << ent[('mineral_saturation_' + benchmark.to_s).to_sym]
          csv_row << ent[('gas_saturation_' + benchmark.to_s).to_sym]
          csv_row << ent[('worker22x_' + benchmark.to_s).to_sym]
        }
        [2,3].each {|benchmark|
          csv_row << ent[('miningbase_' + benchmark.to_s).to_sym]
        }
        [4,5,6,7,8,9,10,12,14,16,18,20,25,30].each {|minute|
          csv_row << ent[('as' + minute.to_s).to_sym]
          csv_row << ent[('w' + minute.to_s).to_sym]
        }
        csv << csv_row 
      }
    }

    header_row = ['id', 'duration_minutes', 'play_date', 'average_league', 'map_name', 'gateway']

    CSV.open('/tmp/matches.csv', 'wb') { |csv|
      csv << header_row
      
      DB.fetch("""
select m.id, m.duration_seconds, m.played_at, m.average_league, m.gateway, map.name
from esdb_matches m, esdb_sc2_maps map
where m.map_id = map.id and
      played_at > '#{PLAYDATE}' and
      m.game_type = '1v1' and
      m.category = 'Ladder' and
      m.vs_ai = 0 and
      m.expansion = 1
""") {|match|
        csv_row = [match[:id], 
                   (match[:duration_seconds] / 60).to_i,
                   match[:played_at].strftime("%F"),
                   match[:average_league],
                   match[:name],
                   match[:gateway]]
        csv << csv_row
      }
    }

    nil

  end

end

