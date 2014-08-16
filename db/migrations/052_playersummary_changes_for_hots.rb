Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_summary_playersummary) do
      add_column(:upgrade_spending_graph_id, Integer, :null => true)
      add_column(:workers_active_graph_id, Integer, :null => true)

      add_column(:enemies_destroyed, Integer, :null => true)
      add_column(:time_supply_capped, Integer, :null => true)
      add_column(:idle_production_time, Integer, :null => true)
      add_column(:resources_spent, Integer, :null => true)
      add_column(:apm, Integer, :null => true)
    end
  end
end
