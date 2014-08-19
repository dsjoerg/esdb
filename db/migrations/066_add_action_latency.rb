Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_entities) do
      add_column(:action_latency_real_seconds, Float, :null => true)
    end
  end
end
