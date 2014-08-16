Sequel.migration do
  up do
    alter_table(:esdb_identities) do
      add_column(:current_rank_1v1, Integer)
      add_column(:current_rank_2v2, Integer)
      add_column(:current_rank_3v3, Integer)
      add_column(:current_rank_4v4, Integer)
      add_column(:current_highest_type, String, :size=>3)
      add_column(:current_highest_league, Integer)
      add_column(:current_highest_leaguerank, Integer)
    end
  end
end
