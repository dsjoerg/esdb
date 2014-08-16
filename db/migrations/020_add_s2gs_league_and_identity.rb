Sequel.migration do
  change do
    alter_table(:esdb_sc2_match_summaries) do
      add_column(:identity_id, Integer)
      add_column(:league, Integer)
    end
  end
end
