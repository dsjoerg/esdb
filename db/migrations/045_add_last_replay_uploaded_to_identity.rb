Sequel.migration do
  up do
    alter_table(:esdb_identities) do
      add_column(:last_replay_uploaded_at, DateTime)
    end
  end
end
