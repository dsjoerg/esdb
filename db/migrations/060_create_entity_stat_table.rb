Sequel.migration do
  change do
    create_table(:esdb_entity_stats) do
      Integer :entity_id
      Integer :highest_league
      
      [2,3].each { |index|
        Integer "base_#{index}".to_sym, :null => true
        Integer "miningbase_#{index}".to_sym, :null => true
      }
      [1,2,3].each { |index|
        Integer "saturation_#{index}".to_sym, :null => true
        Integer "mineral_saturation_#{index}".to_sym, :null => true
        Integer "gas_saturation_#{index}".to_sym, :null => true
        Integer "worker22x_#{index}".to_sym, :null => true
      }

      primary_key [:entity_id]
    end
  end
end
