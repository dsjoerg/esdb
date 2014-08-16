Sequel.migration do
  change do
    alter_table(:esdb_identities) do
      # Last popped from the s2gs queue at
      # (Updated by s2gs/queue/pop)
      add_column(:last_s2gsq_at, DateTime)

      # Last Replay played_at (not Match!)
      # (Updated by Replay#postprocess!)
      add_column(:last_replay_played_at, DateTime)
    end
  end
end
