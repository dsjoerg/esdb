Sequel.migration do
  up do
    alter_table(:esdb_identities) do
      add_column(:blocked, Integer, :null => true)
    end
  end
end
