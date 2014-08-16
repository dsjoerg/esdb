Sequel.migration do
  change do
    alter_table(:esdb_sc2_match_entities) do
      add_column(:highest_league, Integer)
      add_column(:highest_league_gametype, Integer)
    end
  end
end
