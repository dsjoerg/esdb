Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_summary_playersummary) do
      set_column_allow_null :build_order_id, true
      set_column_allow_null  :army_graph_id, true
      set_column_allow_null  :income_graph_id, true
      set_column_allow_null  :resources, true
      set_column_allow_null  :units, true
      set_column_allow_null  :structures, true
      set_column_allow_null  :overview, true
      set_column_allow_null  :average_unspent_resources, true
      set_column_allow_null  :resource_collection_rate, true
      set_column_allow_null  :workers_created, true
      set_column_allow_null  :units_trained, true
      set_column_allow_null  :killed_unit_count, true
      set_column_allow_null  :structures_built, true
      set_column_allow_null  :structures_razed_count, true
    end
  end
end
