Sequel.migration do
  change do
    create_table(:esdb_blobs) do
      String  :source
      column  :data, File
      DateTime :created_at
    end
  end
end
