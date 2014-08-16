Sequel.migration do

  change do
    alter_table(:esdb_sc2_match_replays) do
      add_column(:hidden, Integer, :null=>false)
    end
  end
end
