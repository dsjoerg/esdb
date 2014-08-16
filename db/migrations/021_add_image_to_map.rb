Sequel.migration do
  change do
    alter_table(:esdb_sc2_maps) do
      add_column(:image, String)
    end
  end
end
