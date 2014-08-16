Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_entities) do
      add_column(:race_macro, Float)
    end
  end
end
