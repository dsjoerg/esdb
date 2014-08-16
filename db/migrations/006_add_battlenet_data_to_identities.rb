# I'm not a friend of this, but I'm also not a fan of making things more 
# complicated for style reasons right now.
# TODO: we eventually want this to not be in the generic identities table
# but for now, it'll stay there (as with all previous battle.net related stuff)

Sequel.migration do
  change do
    alter_table(:esdb_identities) do
      add_column(:most_played_race, String, :size => 1)

      add_column(:highest_league_1v1, Integer)
      # Temporary until we gather team leagues individually
      add_column(:highest_team_league, Integer)
      add_column(:highest_league_2v2, Integer)
      add_column(:highest_league_3v3, Integer)
      add_column(:highest_league_4v4, Integer)

      add_column(:current_league_1v1, Integer)
      add_column(:current_league_2v2, Integer)
      add_column(:current_league_3v3, Integer)
      add_column(:current_league_4v4, Integer)

      add_column(:achievement_points, Integer)
      add_column(:season_games, Integer)
      add_column(:career_games, Integer)
      add_column(:most_played, String, :size => 3)

      add_column(:portrait, String)
    end
  end
end
