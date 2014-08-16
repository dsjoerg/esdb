Sequel.migration do
  up {
    run 'create table esdb_sc2_match_matchups (
  id bigint(20) not null auto_increment,
  match_id bigint(20) not null,
  matchup tinyint(4) not null,
  PRIMARY KEY (`id`),
  KEY (`match_id`),
  KEY `matchup` (`matchup`)
) ENGINE=InnoDB
'
    run 'insert into esdb_sc2_match_matchups (match_id, matchup)
select distinct t1.match_id, 1
from esdb_sc2_match_entities t1, esdb_sc2_match_entities t2
where t1.match_id = t2.match_id and
      t1.id != t2.id and
      t1.race = "p" and
      t2.race = "p"
'
    run 'insert into esdb_sc2_match_matchups (match_id, matchup)
select distinct t1.match_id, 2
from esdb_sc2_match_entities t1, esdb_sc2_match_entities t2
where t1.match_id = t2.match_id and
      t1.id != t2.id and
      t1.race = "p" and
      t2.race = "t"
'
    run 'insert into esdb_sc2_match_matchups (match_id, matchup)
select distinct t1.match_id, 3
from esdb_sc2_match_entities t1, esdb_sc2_match_entities t2
where t1.match_id = t2.match_id and
      t1.id != t2.id and
      t1.race = "p" and
      t2.race = "z"
'
    run 'insert into esdb_sc2_match_matchups (match_id, matchup)
select distinct t1.match_id, 4
from esdb_sc2_match_entities t1, esdb_sc2_match_entities t2
where t1.match_id = t2.match_id and
      t1.id != t2.id and
      t1.race = "t" and
      t2.race = "t"
'
    run 'insert into esdb_sc2_match_matchups (match_id, matchup)
select distinct t1.match_id, 5
from esdb_sc2_match_entities t1, esdb_sc2_match_entities t2
where t1.match_id = t2.match_id and
      t1.id != t2.id and
      t1.race = "t" and
      t2.race = "z"
'
    run 'insert into esdb_sc2_match_matchups (match_id, matchup)
select distinct t1.match_id, 6
from esdb_sc2_match_entities t1, esdb_sc2_match_entities t2
where t1.match_id = t2.match_id and
      t1.id != t2.id and
      t1.race = "z" and
      t2.race = "z"
'
  }
end
