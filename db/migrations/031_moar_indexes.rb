Sequel.migration do
  change do
    alter_table(:esdb_identities) do
      drop_index :highest_league, :name=>:highest_league
      add_index([:current_highest_league], :name=>:current_highest_league)
      add_index([:current_highest_type], :name=>:current_highest_type)
    end
  end
end
