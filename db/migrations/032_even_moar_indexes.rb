Sequel.migration do
  up {
    run 'create index thing on esdb_sc2_match_replay_minutes (entity_id, minute)'
    run 'create temporary table minutes_to_die
select distinct m1.id
from esdb_sc2_match_replay_minutes m1, esdb_sc2_match_replay_minutes m2
where m1.entity_id = m2.entity_id
and m1.minute = m2.minute
and m1.id < m2.id
'
    run 'delete esdb_sc2_match_replay_minutes from esdb_sc2_match_replay_minutes
inner join minutes_to_die on minutes_to_die.id = esdb_sc2_match_replay_minutes.id
'
    run 'alter table esdb_sc2_match_replay_minutes drop index thing
'
    run 'create unique index thing on esdb_sc2_match_replay_minutes (entity_id, minute)
'
  }
end
