Sequel.migration do
  up do
    alter_table(:esdb_identities) do
      add_column(:last_stats_refresh, DateTime, :null => true)
    end
  end
end
