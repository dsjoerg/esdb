Sequel.migration do
  up do
    alter_table(:esdb_matches) do
      add_column(:vs_ai, Integer, :null => true)
      add_column(:ranked, Integer, :null => true)
    end
  end
end
