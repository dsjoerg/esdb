# This is what was "aggregatestat" on legacy ggtracker.
# The model is keyed by [stat, minute, league, race, game_type]
#
# stat is a numeric ID for a fixed set of stats that we aggregate
# (STATS index)
#
# TODO: I would like this to be used automatically by StatBuilder to cache
# and retrieve cached statistics, but we're tight on time, so it's directly
# used instead of StatBuilder in matches/index for example to deliver the
# league/league range apm/wpm values.

class ESDB::AggregateStat < Sequel::Model(:esdb_sc2_aggregate_stats)
  STATS = [:apm, :wpm]

  set_primary_key [:stat, :minute, :league, :race, :game_type]
  unrestrict_primary_key 
  
  # Recalculates all stats, very unoptimized, takes several minutes to complete
  def self.recalc!
    # Truncating would be easy but might leave a few requests in the dark
    # TODO:
    # so let's update instead and DELETE min>max() at the end
    Sc2::GAME_TYPES.each do |game_type|
      Sc2::RACES.each do |race|
        dataset = Match.for_race(race).where(game_type: game_type)
        stats = []

        # TODO: one way this can be sped up:
        # somehow make statbuilder realize that both apm and wpm queries can
        # be retrieved using a single query. I'd rather not do this with a
        # crazy hack as it'll only cut off seconds now..
        STATS.each_with_index do |stat_name, stat_idx|
          Sc2::LEAGUES.each_with_index do |league, i|
            stats << "minutes.#{stat_name}(mavg:[<#{race.downcase},L#{i}])"
          end
        end # stats

        apm = ESDB::StatBuilder.new(stats: stats.join(','), dataset: dataset.entities)
        apm = apm.to_hash
        
        STATS.each_with_index do |stat_name, stat_idx|
          Sc2::LEAGUES.each_with_index do |league, i|
            _apm = apm[:"minutes.#{stat_name}"][:mavg]["race_#{race.downcase}_in_league_#{i}".to_sym]

            # We only really want/need the first 20 minutes or so, no?
            _apm[0..30].each_with_index do |x, minute|
              # There is no minute 0, silly.
              stat = self[[stat_idx, minute+1, i, race, game_type]] || self.create(stat: stat_idx, minute: minute+1, league: i, race: race, game_type: game_type)
              stat.value = x
              stat.save
            end
          end
        end

      end #races
    end # game_types

    true
  end
end