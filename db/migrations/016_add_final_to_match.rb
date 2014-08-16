Sequel.migration do
  change do
    alter_table(:esdb_matches) do
      # Note: I'm calling it state, but it really only has two states right
      # now, so the Model will use this as "final", Boolean.c
      add_column(:state, Integer)
    end
  end
end
