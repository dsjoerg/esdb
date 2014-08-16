Sequel.migration do
  up do
    alter_table(:esdb_sc2_match_summaries) do
      set_column_type :gateway, String, :size => 3
    end
  end
end
