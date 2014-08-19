Sequel.migration do
  change do
    alter_table(:esdb_sc2_match_entities) do
      set_column_allow_null(:match_id)
    end
  end
end
