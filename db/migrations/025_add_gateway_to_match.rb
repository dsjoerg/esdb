Sequel.migration do
  change do
    alter_table(:esdb_matches) do
      add_column(:gateway, String, :size => 3)
    end
  end
end
