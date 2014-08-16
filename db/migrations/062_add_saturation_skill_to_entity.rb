Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_entities) do
      add_column(:sat_1_skill, Float)
      add_column(:sat_2_skill, Float)
      add_column(:sat_3_skill, Float)
      add_column(:saturation_skill, Float)
    end
  end
end
