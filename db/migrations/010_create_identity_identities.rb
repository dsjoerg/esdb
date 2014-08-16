Sequel.migration do
  change do
    create_table(:esdb_identity_identities) do
      Integer :left_id, :null => false
      Integer :right_id, :null => false
    end
  end
end
