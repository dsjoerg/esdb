Sequel.migration do
  change do
    create_table(:esdb_matches_deleted) do
      Integer :match_id
      Integer :user_id
      DateTime :deleted_at

      primary_key [:match_id]
    end
  end
end
