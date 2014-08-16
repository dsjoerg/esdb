Sequel.migration do
  change do
    alter_table(:esdb_identities) do
      add_column(:profile_url, String)
    end
  end
end
