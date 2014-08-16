Sequel.migration do
  up do
    alter_table(:esdb_matches) do
      add_column(:cobrand, Integer, :null => true)
    end
  end
end
