Sequel.migration do
  up do
    alter_table(:esdb_identities) do
      add_column(:name_valid_at, DateTime, :default => Time.now)
      add_column(:name_source, String, :size => 16, :default => 'legacy')
    end
  end
end
