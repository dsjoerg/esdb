require 'csv'

LIMIT_CLAUSE = false ? 'limit 50' : ''
PLAYDATE = '2014-08-01'


# computes a preconfigured set of stats

class ESDB::ScoutBuilder

  def self.do_it()

    header_row = ['entity_id', 'minute', 'as']
    0.upto(19).each{|unitnum|
      header_row << 'u' + unitnum.to_s
    }

    CSV.open('/tmp/minutes.csv', 'wb') { |csv|
      csv << header_row

      [4,5,6,7,8,9,10,12,14,16,18,20,25,30].each {|time|
      
      DB.fetch("""
select mrm.entity_id, mrm.minute, mrm.armystrength,
mrm.u0,
mrm.u1,
mrm.u2,
mrm.u3,
mrm.u4,
mrm.u5,
mrm.u6,
mrm.u7,
mrm.u8,
mrm.u9,
mrm.u10,
mrm.u11,
mrm.u12,
mrm.u13,
mrm.u14,
mrm.u15,
mrm.u16,
mrm.u17,
mrm.u18,
mrm.u19
from esdb_matches m, esdb_sc2_match_replay_minutes mrm, esdb_sc2_match_entities e
where mrm.entity_id = e.id and
      e.match_id = m.id and
      m.played_at > '#{PLAYDATE}' and
      m.game_type = '1v1' and
      m.category = 'Ladder' and
      m.vs_ai = 0 and
      m.expansion = 1 and
      mrm.minute = #{time}
  #{LIMIT_CLAUSE}
""") {|minute|
        csv_row = [minute[:entity_id], minute[:minute], minute[:armystrength]]
        0.upto(19).each{|unitnum|
          csv_row << minute[('u' + unitnum.to_s).to_sym]
        }
        csv << csv_row 
      }
    }
    }


    header_row = ['match_id', 'identity_id', 'entity_id', 'race', 'win', 'chosen_race', 'apm', 'action_latency_real_seconds', 'spending_skill', 'race_macro']
    [1,2,3].each {|benchmark|
      header_row << 'mineral_sat_' + benchmark.to_s
      header_row << 'gas_sat_' + benchmark.to_s
      header_row << 'worker22x_' + benchmark.to_s
    }
    [2,3].each {|benchmark|
      header_row << 'miningbase_' + benchmark.to_s
    }

    CSV.open('/tmp/ents.csv', 'wb') { |csv|
      csv << header_row
      
      DB.fetch("""
select e.match_id, eie.identity_id, e.id, e.race, e.win, e.chosen_race, e.apm, e.spending_skill, e.race_macro, e.action_latency_real_seconds, ees.miningbase_2, ees.miningbase_3,
ees.mineral_saturation_1, ees.gas_saturation_1, ees.worker22x_1,
ees.mineral_saturation_2, ees.gas_saturation_2, ees.worker22x_2,
ees.mineral_saturation_3, ees.gas_saturation_3, ees.worker22x_3
from   
( select id, game_type, category, vs_ai, expansion from esdb_matches where played_at > '#{PLAYDATE}' ) rm,
esdb_entity_stats ees,
esdb_identity_entities eie,
esdb_sc2_match_entities e
where e.match_id = rm.id and
      ees.entity_id = e.id and
      eie.entity_id = e.id and
      rm.game_type = '1v1' and
      rm.category = 'Ladder' and
      rm.vs_ai = 0 and
      rm.expansion = 1
  #{LIMIT_CLAUSE}
""") {|ent|
        csv_row = [ent[:match_id], ent[:identity_id], ent[:id], ent[:race], ent[:win], ent[:chosen_race], ent[:apm].to_i,
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

