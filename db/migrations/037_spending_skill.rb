Sequel.migration do
  up {
    run 'DROP TABLE IF EXISTS replays_sq_skill_stat'
    run 'CREATE TABLE replays_sq_skill_stat
select league,
       m.gateway,
       e.race,
       floor(m.duration_seconds/60.0) as mins,
       avg(35.0 * (0.00137 * resource_collection_rate - ln(average_unspent_resources)) + 240) as SQ
from esdb_sc2_match_summaries s, esdb_sc2_match_summary_playersummary ps,
     esdb_sc2_match_entities e, esdb_matches m
where ps.entity_id = e.id and
      e.match_id = m.id and
      s.match_id = m.id and
      league is not null and
      m.gateway is not null and
      m.game_type = "1v1" and
      m.category = "Ladder" and
      resource_collection_rate > 600 and
      average_unspent_resources > 0 and
      duration_seconds >= 300 and
      duration_seconds < 1800
group by m.gateway, league, mins, race
order by m.gateway, league, mins asc, race
'
  }
end
