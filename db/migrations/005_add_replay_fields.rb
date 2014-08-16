Sequel.migration do

  # big ideas for this migration:
  #
  # * replay is just the replay file itself. it has an md5 and upload/processed timestamps. it has one or more providers.
  # * there are one or more replays for one match.
  # * the match has most of what we care about -- a winner, a category, game_type, duration, a map.
  # * the entities are tied to matches (not replays)
  #

  change do
    alter_table(:esdb_matches) do
      add_column(:winning_team, Integer)
      add_column(:category, String, :size=>10)
      add_column(:game_type, String, :size=>10)
      add_column(:average_league, Integer)
      add_column(:duration_seconds, Integer)
      add_column(:release_string, String, :size=>64)
      add_column(:played_at, DateTime)
      add_column(:map_id, Integer)
    end
    
    alter_table(:esdb_sc2_match_replays) do
      drop_column(:provider_id)
      drop_column(:release_string)
      drop_column(:played_at)
      drop_column(:map_id)
      rename_column(:duration, :duration_seconds)
      add_column(:match_id, Integer, :null=>false)
      add_index([:match_id], :name=>:match_id)
    end
    
    alter_table(:esdb_sc2_match_entities) do
      add_column(:team, Integer)
      add_column(:chosen_race, String, :size=>1)
      add_column(:color, String, :size=>6)
      add_column(:armies_by_frame, String, :size=>1000000)
      # drop_index(:replay_id)
      rename_column(:replay_id, :match_id)
      add_index [:match_id], :name=>:match_id
      drop_column(:identity_id)
    end

    create_table(:esdb_sc2_match_replay_providers) do
      Integer :provider_id, :null=>false
      Integer :replay_id, :null=>false
      
      primary_key [:provider_id, :replay_id]
      
      index [:provider_id], :name=>:provider_id
      index [:replay_id], :name=>:replay_id
    end
  end
end
