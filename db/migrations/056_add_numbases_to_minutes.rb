Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_replay_minutes) do
      add_column(:numbases, Integer, :null => true)
    end
  end
end
