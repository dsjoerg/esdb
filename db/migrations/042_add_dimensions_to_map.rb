Sequel.migration do
  up do
    alter_table(:esdb_sc2_maps) do
      add_column(:image_scale, Float)
      add_column(:transX, Integer)
      add_column(:transY, Integer)
    end
  end
end
