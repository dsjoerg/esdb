Sequel.migration do
  up do
    alter_table(:esdb_matches) do
      add_column(:expansion, Integer, :default => 0)
    end
  end
end
