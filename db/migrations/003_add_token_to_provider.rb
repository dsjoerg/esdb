Sequel.migration do
  change do
    alter_table(:esdb_providers){ add_column(:access_token, String) }
  end
end
