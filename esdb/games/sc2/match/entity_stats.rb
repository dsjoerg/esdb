class ESDB::Match::EntityStats < Sequel::Model(:esdb_entity_stats)

  many_to_one :entity, :class => 'ESDB::Sc2::Match::Entity'

  def to_builder(options = {})
    builder = options[:builder] || jbuilder(options)

    builder.(self, :entity_id, :highest_league)
      
    [2,3].each { |index|
      builder.(self, "base_#{index}".to_sym,
               "miningbase_#{index}".to_sym)
    }
    [1,2,3].each { |index|
      builder.(self, "saturation_#{index}".to_sym,
        "mineral_saturation_#{index}".to_sym,
        "gas_saturation_#{index}".to_sym,
        "worker22x_#{index}".to_sym)
    }
    builder
  end
end
