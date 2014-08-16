# A Matchup record states that a given Match features a given Matchup.
# There may be multiple Matchups for a Match (if it is more than a 1v1).
#
# Fields:
# id (pk)
# match_id
# matchup
#
# There are exactly six matchups.  In canonical (alphabetical) order:
#
# 1 PvP
# 2 PvT
# 3 PvZ
# 4 TvT
# 5 TvZ
# 6 ZvZ
#
# So if you want to find all the matches that have Terrans in them, you can select where matchup in (2,4,5)
#
class ESDB::Sc2::Match
  class Matchup < Sequel::Model(:esdb_sc2_match_matchups)

    many_to_one :match, :class => 'ESDB::Match'

    @@matchups = {
      'pvp' => 1,
      'pvt' => 2,
      'pvz' => 3,
      'tvt' => 4,
      'tvz' => 5,
      'zvz' => 6
    }
    
    def self.singlerace_matchup_ids(race)
      case race
      when 'p'
        [1,2,3]
      when 't'
        [2,4,5]
      when 'z'
        [3,5,6]
      else
        nil
      end
    end

    def self.matchup_id(race, vs_race)
      @@matchups[[race, vs_race].sort.join('v')]
    end
  end
end
