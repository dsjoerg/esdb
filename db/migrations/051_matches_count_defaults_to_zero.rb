Sequel.migration do
  up do
    alter_table(:esdb_identities) do
      set_column_default :matches_count, 0
    end
  end
end
