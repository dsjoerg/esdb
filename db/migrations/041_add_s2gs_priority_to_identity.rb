Sequel.migration do
  up do
    alter_table(:esdb_identities) do
      add_column(:s2gs_priority, Integer)
    end
  end
end
