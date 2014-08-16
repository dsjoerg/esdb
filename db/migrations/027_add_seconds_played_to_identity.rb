Sequel.migration do
  up do
    alter_table(:esdb_identities) do
      add_column(:seconds_played_sum, Integer, :default => 0)
    end
    self[:esdb_identities].all do |r|
      update_ds = DB["UPDATE esdb_identities SET seconds_played_sum = (SELECT sum(`duration_seconds`) FROM `esdb_matches` INNER JOIN `esdb_sc2_match_entities` ON (`esdb_sc2_match_entities`.`match_id` = `esdb_matches`.`id`) INNER JOIN `esdb_identity_entities` ON ((`esdb_identity_entities`.`entity_id` = `esdb_sc2_match_entities`.`id`) AND (`esdb_identity_entities`.`identity_id` = ?))) where id = ?", r[:id], r[:id]]
      update_ds.update
    end
  end
end
