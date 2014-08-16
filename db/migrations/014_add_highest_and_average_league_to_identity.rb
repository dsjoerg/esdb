# For the record: (who reads these? I don't! :p)
# We should add highest/average_league_XvX using historic data for the leagues
# later on.. because averaging between 1v1 and 4v4 really makes this useless.
# A player can be Diamond in 4v4 because he got lucky and really be a Bronze
# player in 1v1.

Sequel.migration do
  change do
    alter_table(:esdb_identities) do
      add_column(:highest_league, Integer)
      add_column(:average_league, Integer)
    end
  end
end
