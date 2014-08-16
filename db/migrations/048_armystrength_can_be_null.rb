Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_replay_minutes) do
      set_column_type :armystrength, Integer, :null => true
    end
  end
end
