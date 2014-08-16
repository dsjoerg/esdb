Sequel.migration do
  change do
    alter_table(:esdb_matches) do
      # used by players#show and matches#index
      add_index([:game_type], :name=>:game_type)
      add_index([:map_id], :name=>:map_id)

      # used by matches#index
      add_index([:average_league], :name=>:average_league)
      add_index([:gateway], :name=>:gateway)

      # not used yet in queries, but it will be
      add_index([:category], :name=>:category)
    end
    alter_table(:esdb_identities) do
      # used by players#index
      add_index([:highest_league], :name=>:highest_league)
      add_index([:most_played_race], :name=>:most_played_race)
      add_index([:gateway], :name=>:gateway)
    end
  end
end
