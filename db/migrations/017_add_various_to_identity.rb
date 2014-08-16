Sequel.migration do
  change do
    alter_table(:esdb_identities) do
      # In the spirit of "calling it what it is", I'll refrain from calling
      # these columns apm and wpm :)
      add_column(:avg_apm, Float)
      add_column(:avg_wpm, Float)
      
      # Rails calls this "counter cache", not sure (couldn't find it) if such
      # a mechanism exists for Sequel.. we'll do it manually for now
      add_column(:matches_count, Integer)
      
      # Since all we're using right now is the "highest rank" for 
      # "highest league", that's all I'll add
      add_column(:highest_league_rank, Integer)
    end
  end
end
