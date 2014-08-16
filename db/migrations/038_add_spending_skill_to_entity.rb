Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_entities) do
      add_column(:spending_skill, Float)
    end
  end
end
