Sequel.migration do
  change do
    alter_table(:esdb_identities) do
      add_column(:scrape_job_id, String)
    end
  end
end
