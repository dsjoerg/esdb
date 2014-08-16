Sequel.migration do
  change do
    alter_table(:esdb_matches) do
      add_index([:replays_count], :name=>:replays_count)
    end
  end
end
