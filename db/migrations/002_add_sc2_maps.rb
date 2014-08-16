Sequel.migration do
  change do
    # Need a esdb_sc2_maps dump to work with?
    # https://github.com/downloads/ggtracker/esdb/esdb_sc2_maps.sql
    # (run this migration first, then overwrite with the dump)

    create_table(:esdb_sc2_maps) do
      primary_key :id
      String :name, :size=>255, :null=>false
      String :gateway, :size=>5
      String :s2ma_hash, :size=>255
    end

    # Add map_id to replays
    alter_table(:esdb_sc2_match_replays){ add_column(:map_id, Integer) }
  end
end
