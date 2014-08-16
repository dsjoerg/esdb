Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_entities) do
      add_column(:max_creep_spread, Float, :null => true)
    end
    alter_table(:esdb_sc2_match_replay_minutes) do
      add_column(:creep_spread, Float, :null => true)
    end
  end
end
