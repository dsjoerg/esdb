Sequel.migration do
  change do
    alter_table(:esdb_identities) do
      add_column(:last_scraped_at, DateTime)
    end
  end
end
