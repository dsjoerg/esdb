Sequel.migration do
  change do
    alter_table(:esdb_sc2_match_summaries) do
      add_column(:realm, String, :size => 2)
      add_column(:match_id, Integer)
      drop_column(:resources)
      drop_column(:units)
      drop_column(:structures)
      drop_column(:overview)
      drop_column(:average_unspent_resources)
      drop_column(:resource_collection_rate)
      drop_column(:workers_created)
      drop_column(:units_trained)
      drop_column(:killed_unit_count)
      drop_column(:structures_built)
      drop_column(:structures_razed_count)
      drop_column(:replay_id)
      add_index([:match_id], :name=>:match_id)
    end

    create_table(:esdb_sc2_match_summary_playersummary) do
      primary_key :id, :type=>Bignum
      Integer :entity_id, :null=>false
      Integer :build_order_id, :null=>false
      Integer :army_graph_id, :null=>false
      Integer :income_graph_id, :null=>false
      Integer :resources, :null=>false
      Integer :units, :null=>false
      Integer :structures, :null=>false
      Integer :overview, :null=>false
      Integer :average_unspent_resources, :null=>false
      Integer :resource_collection_rate, :null=>false
      Integer :workers_created, :null=>false
      Integer :units_trained, :null=>false
      Integer :killed_unit_count, :null=>false
      Integer :structures_built, :null=>false
      Integer :structures_razed_count, :null=>false

      index [:entity_id], :name=>:entity_id
    end

    create_table(:esdb_sc2_match_summary_graph) do
      primary_key :id, :type=>Bignum
    end

    create_table(:esdb_sc2_match_summary_graphpoint) do
      primary_key :id, :type=>Bignum
      Integer :graph_id, :null=>false
      Integer :graph_seconds, :null=>false
      Integer :graph_value, :null=>false

      index [:graph_id], :name=>:graph_id
    end

    create_table(:esdb_sc2_match_summary_item) do
      primary_key :id, :type=>Bignum
      String :name, :size=>64, :null=>false
      
      index [:name], :name=>:name
    end

    create_table(:esdb_sc2_match_summary_buildorder) do
      primary_key :id, :type=>Bignum
    end

    create_table(:esdb_sc2_match_summary_buildorderitem) do
      primary_key :id, :type=>Bignum
      Integer :build_order_id, :null=>false
      Integer :item_id, :null=>false
      Integer :build_seconds, :null=>false
      Integer :supply, :null=>false
      Integer :total_supply, :null=>false

      index [:build_order_id], :name=>:build_order_id
      index [:item_id], :name=>:item_id
    end
  end
end
