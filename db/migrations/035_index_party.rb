Sequel.migration do
  change do
    alter_table(:esdb_matches) do
      add_index([:played_at], :name=>:played_at)
    end
    alter_table(:esdb_identities) do
      add_index([:name], :name=>:name)
    end
  end
end
