Sequel.migration do
  change do
    alter_table(:esdb_providers){ add_column(:callback_url, String) }
  end
end
