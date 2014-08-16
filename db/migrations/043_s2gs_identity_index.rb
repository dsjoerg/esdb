Sequel.migration do
  change do
    alter_table(:esdb_sc2_match_summaries) do
      add_index([:identity_id], :name=>:identity_id)
    end
  end
end
