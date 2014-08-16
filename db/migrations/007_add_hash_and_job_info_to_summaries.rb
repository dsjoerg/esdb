Sequel.migration do
  change do
    alter_table(:esdb_sc2_match_summaries) do
      add_column(:s2gs_hash, String)
      add_column(:first_seen_at, DateTime)
      add_column(:processed_at, DateTime)
      add_column(:fetched_at, DateTime)
    end
  end
end
