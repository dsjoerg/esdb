class ESDB::Match::EntitySummary < Sequel::Model(:esdb_sc2_match_summary_playersummary)

  many_to_one :armygraph, :key => :army_graph_id,  :class => 'ESDB::Match::SummaryGraph'
  many_to_one :incomegraph, :key => :income_graph_id, :class => 'ESDB::Match::SummaryGraph'
  many_to_one :workersactivegraph, :key => :workers_active_graph_id, :class => 'ESDB::Match::SummaryGraph'
  many_to_one :upgradespendinggraph, :key => :upgrade_spending_graph_id, :class => 'ESDB::Match::SummaryGraph'

  # there should only be one entity_summary per entity.
  #
  # but when i change the next line to one_to_one, then
  #  entitysummary.entity no longer works.
  #
  many_to_one :entity, :class => 'ESDB::Sc2::Match::Entity'

  @@sq_skill_table = nil

  def spending_quotient
    return nil if average_unspent_resources.nil? || resource_collection_rate.nil? || average_unspent_resources == 0
    35.0 * (0.00137 * resource_collection_rate - Math.log(average_unspent_resources)) + 240
  end


  SMOOTHING_WINDOW = 5
  SS_REGIONS = ['us','eu']

  def self.smooth_by_minute(sq_skill_table)
    smoothed_table = {}
    SS_REGIONS.each { |gateway|
      smoothed_table[gateway] = {}
      5.upto(29).each { |minutes|
        smoothed_table[gateway][minutes] = {'P'=>{}, 'T'=>{}, 'Z'=>{}}
      }
      ['P','T','Z'].each { |race|
        0.upto(6).each { |league|
          5.upto(5 + SMOOTHING_WINDOW - 1).each { |minutes|
            smoothed_table[gateway][minutes][race][league] = sq_skill_table[gateway][minutes][race][league]
          }

          # smoothing part 1: for minutes 10 through 24, set the SQ to
          #  be the average of the range (min-5, min+5).  We believe in linear SQ
          #  there.
          (5 + SMOOTHING_WINDOW).upto(29 - SMOOTHING_WINDOW).each { |minutes|
            smoothmin = minutes - SMOOTHING_WINDOW
            smoothmax = minutes + SMOOTHING_WINDOW
            smoothme = (smoothmin..smoothmax).collect{|sample|
              entry = sq_skill_table[gateway][sample][race][league]
              if entry.nil?
                nil
              else 
                entry[0]
              end
            }
            smoothme.reject!{|x| x.nil?}
            smoothed = smoothme.inject(:+) / smoothme.size
            smoothed_table[gateway][minutes][race][league] = [smoothed, sq_skill_table[gateway][minutes][race][league][1]]
          }
          (29 - (SMOOTHING_WINDOW - 1)).upto(29).each { |minutes|
            smoothed_table[gateway][minutes][race][league] = sq_skill_table[gateway][minutes][race][league]
          }
        }
        5.upto(29).each { |minutes|
          max_sq = 0
          0.upto(6).each { |league|
            # smoothing part 2: SQ must never go the wrong way as a function of league.
            if smoothed_table[gateway][minutes][race][league].present?
              this_sq = smoothed_table[gateway][minutes][race][league][0]
            else
              this_sq = nil
            end
            
            if ((this_sq.present? && this_sq < max_sq) ||
                (this_sq.nil? && max_sq > 0))
              if this_sq.present?
                smoothed_table[gateway][minutes][race][league][0] = max_sq
              else
                smoothed_table[gateway][minutes][race][league] = [max_sq, 0]
              end              
            end
            if (this_sq.present? && this_sq > max_sq)
              max_sq = this_sq
            end
          }
        }
      }
    }
    smoothed_table      
  end

  #
  # sq_skill_table is a
  # map from gateway to a
  # map from game-duration-in-minutes (5...29 inclusive) to a
  # map of race char (as a capital letter) to a
  # map of league number to average-SQ-for-a-league
  #
  def self.get_sq_skill_table
    if @@sq_skill_table.nil? || (Resque.redis.get('sq_should_nuke') == 'YES')
      @@sq_skill_table = {}
      SS_REGIONS.each { |gateway|
        @@sq_skill_table[gateway] = {}
        5.upto(29).each { |minutes|
          @@sq_skill_table[gateway][minutes] = {'P'=>{}, 'T'=>{}, 'Z'=>{}}
        }
      }
      num_rows=0
      # TODO put SS_REGIONS into this query dammit
      DB.fetch("select * from replays_sq_skill_stat where mins >= 5 and mins <= 29 and gateway in ('us','eu')") do |row|
        num_rows = num_rows + 1
        avg_sq_to_league = @@sq_skill_table[row[:gateway]][row[:mins].to_i][row[:race]]
        avg_sq_to_league[row[:league].to_i] = [row[:SQ].to_f, row['count(*)'.to_sym].to_i]
      end
      if num_rows == 0
        raise 'replays_sq_skill_stat table is empty!  i cant live like this'
      end
      @@sq_skill_table = smooth_by_minute(@@sq_skill_table)      
      Resque.redis.set('sq_should_nuke', 'NO')
    end
    return @@sq_skill_table
  end

  # returns a floating-point number indicating the leaguified spending
  #  skill for a given SQ, race, gateway and game duration in minutes.
  #
  # 6 means the SQ is exactly average for grandmaster.
  # 5 means the SQ is exactly average for master.
  # 4 means the SQ is exactly average for diamond.
  # 0 means the SQ is exactly average for bronze or worse.
  #
  # the return value will be a float between 0 and 7.
  # >6 means you're better than the average for GM.
  #
  #
  def spending_skill
    return nil if entity.nil? || entity.match.nil?

    sq = spending_quotient
    race = entity.race
    minutes = (entity.match.duration_seconds.to_f / 60.0).floor
    gateway = entity.match.gateway

    return nil if sq.nil? || gateway.blank?

    # see sq_skill_table comment
    ist = self.class.get_sq_skill_table

    return nil if minutes < 5
    minutes = 29 if minutes > 29

    # until we have spending-skill data for these regions, we'll just
    # use EU.
    if ['kr','cn','sea','xx'].include?(gateway)
      gateway = 'eu'
    end

    league_to_avg_sq = ist[gateway][minutes][race]

    # we place into the best league that our SQ qualifies us for
    league = league_to_avg_sq.select{|league, league_sq| league_sq.present? && league_sq[0].present? && sq >= league_sq[0]}.keys.max
    if league.nil?
      if league_to_avg_sq[0].present?
        league = 0
      else
        # in this situation, we are missing data for the bronze
        # league, and this players SQ isnt better than any of the
        # leagues that we do have data for.  lets just give up and not
        # rate this entity.
        return nil
      end
    end

#    puts "hi, #{sq} #{gateway} #{minutes} #{race} #{league_to_avg_sq} #{league}"


    # if we placed sub-GM, then interpolate our score based on how
    #  close we were to the next league up
    if league < 6
      our_league_sq = league_to_avg_sq[league][0]
      next_league_sq = league_to_avg_sq[league + 1][0]
      if next_league_sq.present? && our_league_sq.present?
        league = league + (sq - our_league_sq)/(next_league_sq - our_league_sq)
      end
    else
      # for GM level performance, lets synthesize the shadow GM league
      #  as one league step above GM
      gm_sq = league_to_avg_sq[6][0]
      if league_to_avg_sq[0].present?
        bronze_sq =  league_to_avg_sq[0][0]
        if bronze_sq.present?
          shadow_sq = gm_sq + (gm_sq - bronze_sq)/6.0
          league = league + (sq - gm_sq)/(shadow_sq - gm_sq)
        end
      end
    end

    league = [7.0, [0.0, league].max].min

    league
  end


  # Serialize to Jbuilder
  def to_builder(options = {})
    builder = options[:builder] || jbuilder(options)

    builder.(self, :id,
  	:build_order_id, :resources, :units, 
  	:structures, :overview, :average_unspent_resources, 
  	:resource_collection_rate, :spending_quotient, :workers_created, :units_trained,
		:killed_unit_count, :structures_built, :structures_razed_count, :spending_skill,
             :enemies_destroyed, :time_supply_capped, :idle_production_time,
             :resources_spent, :apm
    )

    builder.armygraph(armygraph.to_builder) if builder.filter.graphs? and armygraph
    builder.incomegraph(incomegraph.to_builder) if builder.filter.graphs? and incomegraph
    builder.workersactivegraph(workersactivegraph.to_builder) if workersactivegraph && builder.filter.graphs?
    builder.upgradespendinggraph(upgradespendinggraph.to_builder) if upgradespendinggraph && builder.filter.graphs?

    builder
  end
end
