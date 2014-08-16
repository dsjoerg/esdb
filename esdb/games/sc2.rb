class ESDB::Sc2
  GAME_TYPES = ['1v1', '2v2', '3v3', '4v4', 'FFA']
  RACES = ['T', 'P', 'Z']
  LEAGUES = [:bronze, :silver, :gold, :platinum, :diamond, :master, :grandmaster]

  # Putting a bunch of Sc2 related helpers here, maybe throw them into their
  # own module (TODO?)
  def self.gateway_depot_host(gateway)
    "#{gateway}.depot.battle.net:1119"
  end

  # Stat configuration for Sc2, used by StatBuilder::Stat
  #
  # :scope defaults to entities in Stat, it's a good idea to have a scope here
  # that more accurately defines what exactly we want.
  # e.g. for apm, we don't want to count games that have zero apm - BUT,
  # in reality, we don't want games that weren't processed. As soon as we have
  # a 100% accurate indicator of processing state, use that instead (TODO)
  STATS = {
    :apm => {  },
    :wpm => {  },
    :spending_skill => {  },
    :win => {
      :val => true
    },
    :loss => {
      :val => false,
      :attr => :win
    },
    :duration => {
      :attr => :duration_minutes
    }
  }

SC2RANKS_RACE = 
    {
    'P' => 'Protoss',
    'Z' => 'Zerg',
    'T' => 'Terran'
  }


UNITS = 
   {
'Protoss' => [
    'probe',
    'zealot',
    'sentry',
    'stalker',
    'hightemplar',
    'darktemplar',
    'immortal',
    'colossus',
    'archon',
    'observer',
    'warpprism',
    'phoenix',
    'voidray',
    'carrier',
    'mothership',
    'photoncannon',
    'oracle',
    'tempest',
    'mothershipcore',
],
'Terran' => [
    'scv',
    'marine',
    'marauder',
    'reaper',
    'ghost',
    'hellion',
    'siegetank',
    'thor',
    'viking',
    'medivac',
    'banshee',
    'raven',
    'battlecruiser',
    'planetaryfortress',
    'missileturret',
    'widowmine',
],
'Zerg' => [
    'drone',
    'zergling',
    'queen',
    'baneling',
    'roach',
    'overlord',
    'overseer',
    'hydralisk',
    'spinecrawler',
    'sporecrawler',
    'mutalisk',
    'corruptor',
    'broodlord',
    'broodling',
    'infestor',
    'infestedterran',
    'ultralisk',
    'nydusworm',
    'swarmhost',
    'viper',
       ]
  }

UNITTONUMBER = {}
UNITS.values.each do |unitlist|
    unitlist.each_with_index do |unit, index|
      UNITTONUMBER[unit] = index
    end
end

def self.unitNumber(unit)
  return UNITTONUMBER[unit]
end

end
