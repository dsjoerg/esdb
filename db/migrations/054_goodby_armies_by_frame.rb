Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_entities) do
      drop_column :armies_by_frame
    end
  end
end
