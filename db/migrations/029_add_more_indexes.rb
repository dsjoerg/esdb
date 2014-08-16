Sequel.migration do
  change do
    alter_table(:esdb_sc2_match_summaries) do
      add_index([:s2gs_hash], :name=>:s2gs_hash)
    end
    alter_table(:esdb_identities) do
      add_index([:type], :name=>:type)
    end
  end
end
