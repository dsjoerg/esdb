Sequel.migration do
  up do
    alter_table(:esdb_identities) do
      add_column(:last_summary_seen_at, DateTime)
      add_column(:pops_since_summary_seen, Integer, :default => 0)
    end
  end
end
