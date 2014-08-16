Sequel.migration do
  change do
    alter_table(:esdb_matches) do
      # Note: I would like to have these do "traditional" counting, but since
      # sc2reader/ggpyjobs will create most of the data, we can't run any 
      # callbacks and as such only sync these columns in the processing job.
      # keywords: counter_cache, counter cache, sum cache

      add_column(:replays_count, Integer, :default => 0)
      add_column(:summaries_count, Integer, :default => 0)
    end
  end
end
