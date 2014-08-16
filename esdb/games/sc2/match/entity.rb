# The information about what a single player did during a particular
# match is called "Entity".  It's a terrible name, but whatever,
# you'll get used to it.
#
# Other objects that refer to both a player and a game, such as a
#  player-summary from an s2gs file, should refer to this object.
#
class ESDB::Sc2::Match
  class Entity < ESDB::Match::Entity

    # how to switch this to the better Sequel::Model(:dataset_name) form?
    # my rubyfoo not strong enough yet.
#    set_dataset :esdb_sc2_match_entities

    many_to_one :match, :class => 'ESDB::Match'

    one_to_one :summary, :class => 'ESDB::Match::EntitySummary'
    one_to_one :stats, :class => 'ESDB::Match::EntityStats'
    one_to_many :minutes, :class => 'ESDB::Sc2::Match::Replay::Minute'
    one_to_many :identity_entities, :class => 'ESDB::IdentityEntity'
    many_to_many :identities, :join_table => :esdb_identity_entities, :class => 'ESDB::Identity'

    # http://sequel.rubyforge.org/rdoc-plugins/classes/Sequel/Plugins/AssociationDependencies.html
    plugin :association_dependencies, :minutes=>:destroy, :identity_entities=>:destroy


    def winner?
      win?
    end

    def avg(stat = :apm)
      stat = stat.to_sym
      case stat
      when :apm, :wpm
        minutes.avg(stat)
      else
        0.0
      end
    end

    # Prepares chart series data
    # This was gg's Match#chart_data, minus the presentation logic of course
    # TODO: still not happy with this. StatBuilder should take care of this.
    # but, we need to launch already! Also, even if it stays, it needs serious
    # refactoring.
    def smooth(indata, window_size)
      window = []
      result = []
      runningavg = 0
      for elm in indata
        elm = 0 if elm.nil?
        runningavg += elm
        window.push(elm)
        if window.length > window_size
          removedelm = window.shift
          runningavg -= removedelm
        end
        windowavg = runningavg.to_f / window.length
        result.push(windowavg.round(2))
      end
      return result
    end
    
    def chart_data(measure, smoothing_window)
      smooth(minutes.collect(&measure.to_sym), smoothing_window)
    end

    METRIC_NAMES = ['_mineral_saturation_1', '_mdelta2', '_mdelta3']

    def compute_one_saturation_skill(base_num, sat_time)
      return nil if self.match.game_type != '1v1'

      enemy_entity = match.entities.reject{|entity| entity.id == self.id}[0]
      matchup = self.race + 'v' + enemy_entity.race
      league_skill_level = nil
      ssb = self.class.saturation_skill_benchmarks
      1.upto(5).each{|league|
        key = league.to_s + matchup + METRIC_NAMES[base_num - 1]
        if ssb[key].present? && ssb[key]['fit'].present?
          benchmark_seconds = ssb[key]['fit']
          if sat_time.present? && sat_time <= benchmark_seconds
            league_skill_level = league
          end
        else
          # ouch there is some missing data. bail out
          puts "Missing data for #{key}, bailing"
          return nil
        end
      }
      return league_skill_level if league_skill_level.present?

      # so the base wasn't saturated in time to earn silver or better.
      # so is this a bronze or a nil?
      if base_num == 1
        base_build_seconds = 0
      else
        base_build_seconds = self.stats["miningbase_#{base_num}".to_sym]
      end

      # if the base in question was never built, it's a nil
      if base_build_seconds.nil?
        # print "base was never built"
        return nil
      end

      # if the game ended before the silver benchmark time, it's a nil
      silver_key = '1' + matchup + METRIC_NAMES[base_num - 1]
      if ssb[silver_key].present? && ssb[silver_key]['fit'].present?
        silver_threshold = base_build_seconds + ssb[silver_key]['fit']
        if match.duration_seconds < silver_threshold
          # print "game ended before silver threshold"
          return nil
        end
      else
          # ouch there is some missing data. bail out
        puts "Missing data for #{silver_key}, bailing"
        return nil
      end

      # OK, it's bronze.
      return 0
    end

    def compute_saturation_skill
      return nil if self.stats.nil?

      mdelta = {}
      [2,3].each {|basenum|
        sat_time = self.stats["mineral_saturation_#{basenum}".to_sym]
        miningbase_time = self.stats["miningbase_#{basenum}".to_sym]
        if miningbase_time.nil? || sat_time.nil?
          mdelta[basenum] = nil
        else
          mdelta[basenum] = [0,sat_time - miningbase_time].max
        end
      }

      self.sat_1_skill = compute_one_saturation_skill(1, self.stats.mineral_saturation_1)
      self.sat_2_skill = compute_one_saturation_skill(2, mdelta[2])
      self.sat_3_skill = compute_one_saturation_skill(3, mdelta[3])
      self.saturation_skill = [sat_1_skill, sat_2_skill, sat_3_skill].compact.min
    end

    def to_builder(options = {})
      builder = super(options)
      # We end up with a segfault in yajl here if we pass on the builder
      # reference coming in from matches.rb's array! call. It looked like a
      # circular reference, I'm not sure though and we actually really don't
      # want to pass around that reference anyway.
      # TODO: potential debugging, confirm circular reference, pass on options
      # directly to to_builder below to break.
      builder.summary(summary ? summary.to_builder(filter: builder.filter).attributes! : nil) if builder.filter.entity.summary?

      builder.stats(stats ? stats.to_builder.attributes! : nil)

      builder.data({
        apm: chart_data('apm', 1),
        wpm: chart_data('wpm', 1),
        creep_spread: chart_data('creep_spread', 1),
      }) if builder.filter.graphs?

      builder
    end

    def self.saturation_skill_benchmarks_json
      return @ssb_json if @ssb_json.present? && Time.now < @ssb_json_valid_until
      @ssb_json = self.saturation_skill_benchmarks.to_json
      @ssb_json_valid_until = Time.now + 60 * 60
      @ssb_json
    end

    def self.saturation_skill_benchmarks

      return @ssb if @ssb.present? && Time.now < @ssb_valid_until

      cachekey = 'econ_staircase'
      jsonresult = Resque.redis.get(cachekey)
      if jsonresult.present?
        @ssb = JSON.load(jsonresult)
        @ssb_valid_until = Time.now + 60 * 60
        return @ssb
      end

      ESDB.log("cache miss for staircase econ stats")
      @ssb = self.compute_saturation_skill_benchmarks
      @ssb_valid_until = Time.now + 60 * 60
      jsonresult = @ssb.to_json
      Resque.redis.set(cachekey, jsonresult)
      @ssb = JSON.load(jsonresult)
      @ssb
    end

    FOREVER = 16 * 60 * 60 * 10 # 10 hours, ie it never happened

    def self.compute_saturation_skill_benchmarks
      result = {}
      query = """
select ees.highest_league, e1.race as race, e2.race as vs_race,
  mineral_saturation_1,
  miningbase_2, mineral_saturation_2,
  miningbase_3, mineral_saturation_3
from esdb_entity_stats ees,
     esdb_matches m,
	 esdb_sc2_match_entities e1,
     esdb_sc2_match_entities e2
where m.category = 'Ladder'
  and m.game_type = '1v1'
  and m.gateway != 'xx'
  and m.vs_ai = 0
  and e1.id != e2.id
  and m.played_at > '2013-05-06'
  and e1.match_id = m.id
  and e2.match_id = m.id
  and e1.id = ees.entity_id
  and ees.highest_league >= 0
  and ees.highest_league <= 6
"""

      gamestats = {}

      values_for_mean = {}
      values_for_median = {}

      DB.fetch(query) do |row|
        key = row[:highest_league].to_s + row[:race] + 'v' + row[:vs_race] + '_mineral_saturation_1'
        values_for_mean[key] ||= []
        values_for_median[key] ||= []
        mskey = :mineral_saturation_1
        if row[mskey].present?
          values_for_mean[key] << row[mskey]
          values_for_median[key] << row[mskey]
        else
          values_for_median[key] << FOREVER
        end
        
        [2,3].each { |basenum|
          key = row[:highest_league].to_s + row[:race] + 'v' + row[:vs_race] + '_mdelta' + basenum.to_s
          
          values_for_mean[key] ||= []
          values_for_median[key] ||= []

          mbkey = ('miningbase_' + basenum.to_s).to_sym
          mskey = ('mineral_saturation_' + basenum.to_s).to_sym
          if row[mbkey].present?
            if row[mskey].present?
              values_for_mean[key] << [row[mskey] - row[mbkey], 0].max
              values_for_median[key] << [row[mskey] - row[mbkey], 0].max
            else
              values_for_median[key] << FOREVER
            end
          end
        }
      end

      result = {}
      values_for_mean.keys.each { |key|
        result[key] = {
          :mean => values_for_mean[key].avg,
          :median => values_for_mean[key].median,
          :mean_count => values_for_mean[key].count,
          :median_count => values_for_median[key].count
        }
      }

      ['_mineral_saturation_1', '_mdelta2', '_mdelta3'].each{|metric|
        ['PvP','PvZ','PvT','ZvP','ZvZ','ZvT','TvP','TvZ','TvT'].each {|matchup|
          medians = []
          1.upto(5).each{|league|
            key = league.to_s + matchup + metric
            medians << result[key][:median] if result[key].present?
          }
          if (medians.count == 5)
            bestfit = Statsample::Regression::Simple.new_from_vectors((1..5).to_a.to_scale, medians.to_scale)
            1.upto(5).each{|league|
              key = league.to_s + matchup + metric
              
              # if the bestfit line slopes in the direction of
              # higher-league players doing things faster, then we
              # use it.  but if it slopes the 'wrong' way, then
              # TheStaircase benchmark is the Masters level
              # performance.
              if bestfit.b < 0
                result[key][:fit] = bestfit.y(league)
              else
                result[key][:fit] = result['5' + matchup + metric][:median]
              end

            }
          end
        }
      }

      result['now'] = Time.now
      result
    end

  end
end
