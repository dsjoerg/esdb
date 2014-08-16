#
# StatBuilder is the parent to Stat, which in turn runs calculations on a given
# metric to produce a statistical value.
#
# One simply passes a StatsParam string to :stat in the StatBuilder constructor
# then calls #build! to create all Stats and get them in an Array from the
# StatBuilder object by calling #to_hash
#
# Stat creates conditions from the StatsParam string for its stat and passes
# these to Query which in turn produces a "scope" for Stat and call the
# aggregate function correctly by calling Query#calc
#
# Query uses SQLBuilder to produce the Sequel scope, which resolves conditions
# into a sequel chain, which in turn produces the correct SQL.
#

class ESDB::StatBuilder
  attr_accessor :options, :built, :stats, :data

  def initialize(opts = {})
    @stats = {}
    @options = Options.new(opts)
    @options[:identities] = @options.identities.collect{|_id| ESDB::Identity[_id]} if @options.identities.any?

    # If we're being given identities and :summary isn't true, we want to
    # return stats for each identity.

    #
    # @options.stats is given as a string via the API, such as
    #  "apm(mavg:[<126228]),wpm(mavg:[<126228,E4]),spending_skill(avg:[<126228]),
    #   spending_skill(mavg:[<126228]),
    #   win(mavg:[<126228]),win(count:[<126228]),loss(count:[<126228])"
    #
    # It is transformed into a data structure by stat_builder/options.rb
    # which uses the grammar defined in lib/grammars/stats_param.citrus
    # 
    # It becomes an array of [metric, calcs]
    # where metric is apm, wpm, spending_skill
    # and calcs is mavg, avg, count
    #

    if @options.stats
      if @options.identities.any? && !@options.summarize?
        for identity in @options.identities
          @stats[identity.id] = @options.stats.collect do |metric, calcs|
            Stat.new(self, :identity => identity, :metric => metric, :calculations => calcs)
          end
        end
      else
        @stats = @options.stats.collect do |metric, calcs|
          Stat.new(self, :metric => metric, :calculations => calcs)
        end
      end
    end
  end

  def identities
    @options.identities || []
  end
  
  def summarize?
    @options.summarize || false
  end
  
  def built?
    @built == true
  end

  # Build the statistics hash
  def build!(rebuild = false)
    return true if @built && !rebuild

    # Determine the set of entities to use
    if identities.any? && !summarize?
      for identity in options.identities
        stats[identity.id].each do |stat|
          stat.calc!
        end
      end
    else
      stats.each do |stat|
        stat.calc!
      end
    end

    @built = true
  end

  def to_hash
    return @data if @data

    build! if !built?

    _stats = {}
    if identities.any? && !summarize?
      for identity in options.identities
        stats[identity.id].each do |stat|
          _stats[identity.id] ||= {}
          _stats[identity.id][:identity] = identity.to_hash
          _stats[identity.id][stat.to_sym] = stat.to_hash
        end
      end
    else
      stats.each do |stat|
        _stats[stat.to_sym] = stat.to_hash
      end
    end

    @data = _stats

    return @data
  end
  
  def to_json
    to_hash.to_json    
  end
end
