Sequel.migration do
  change do
    create_table(:esdb_pack) do
      Integer :pack_id
      String :name
      primary_key [:pack_id]
    end

    create_table(:esdb_match_pack) do
      Integer :match_pack_id
      Integer :pack_id
      Integer :match_id
      primary_key [:match_pack_id]
      index [:pack_id], :name=>:pack_id
    end
  end
end
