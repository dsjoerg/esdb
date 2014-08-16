Sequel.migration do
  change do
    create_table(:esdb_sc2_match_summary_mapfacts) do
      primary_key :id, :type=>Bignum

      String :map_name, :null=>false, :size => 100
      String :map_description, :null=>false, :size => 1000
      String :map_tileset, :null=>false, :size => 100

      index [:map_name, :map_description, :map_tileset], :name=>:allfields
      index [:map_name], :name=>:map_name
    end
    
    alter_table(:esdb_sc2_match_summaries) do
      add_column(:mapfacts_id, Integer)
    end
  end
end
