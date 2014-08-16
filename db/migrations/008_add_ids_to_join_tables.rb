Sequel.migration do
  change do
    alter_table(:esdb_identity_entities) do
      add_column(:id, Integer)
    end

    alter_table(:esdb_sc2_match_replay_providers) do
      add_column(:id, Integer)
    end
  end
end
