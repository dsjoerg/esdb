Sequel.migration do
  change do
    create_table(:esdb_sc2_aggregate_stats) do
      Integer :stat
      Integer :minute
      Integer :league
      String  :race
      String  :game_type

      Double  :value

      primary_key [:stat, :minute, :league, :race, :game_type]
    end
  end
end
