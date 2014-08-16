# Adds state and status, used (soon) to make the models act as state machine
# to have more control over/info on their state.

Sequel.migration do
  change do
    # Match already had #state, but it was an integer.. I prefer integers
    # but for the sake of a speedy implementation, we'll stick to strings :(
    alter_table(:esdb_matches) do
      set_column_type(:state, String, :size => 16)
    end

    [:esdb_identities, :esdb_sc2_match_replays, :esdb_sc2_match_summaries].each do |table|
      alter_table(table) do
        add_column(:state, String, :size => 16)
        add_column(:status, String)
      end
    end
  end
end
