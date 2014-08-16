# The Stat Class represents a metric with one or more calculations
# e.g. the "apm" metric with "avg" calculation.

class ESDB::StatBuilder
  class Stat < Hash
    include Hashie::Extensions::KeyConversion
    include Hashie::Extensions::MethodAccess

    attr_accessor :data, :config, :stat_builder

    def initialize(stat_builder = nil, opts = {})
      if stat_builder.is_a?(Hash)
        opts = stat_builder
      else
        @stat_builder = stat_builder
      end

      merge!(opts)
      symbolize_keys!

      self[:calculations] = {self[:calculations] => nil} if !self[:calculations].is_a?(Hash)

      @config = Hashie::Mash.new(ESDB::Sc2::STATS[metric.to_sym])
    end

    def identity
      key?(:identity) ? self[:identity] : nil
    end

    # Return a descriptive key for a given condition
    def condition_key(condition)
      case condition
      # '<>' <race> played/vs
      when Query::CONDREG[:race] then "race_#{$1}"
      when Query::CONDREG[:vs_race] then "vs_race_#{$1}"

      # '<' <identity>
      when Query::CONDREG[:as_identity] then "as_identity_#{$1}"

      # '>' <identity>
      when Query::CONDREG[:vs_identity] then "vs_identity_#{$1}"

      # At timestamp (minute)
      when Query::CONDREG[:at_minute] then "at_minute_#{$1}"

      # After timestamp (minute)
      when Query::CONDREG[:after_minute] then "after_minute_#{$1}"

      when Query::CONDREG[:not] then "not_#{$1}"

      when Query::CONDREG[:after_date] then "after_date_#{$1}"

      when Query::CONDREG[:before_date] then "before_date_#{$1}"

      when Query::CONDREG[:in_league] then "in_league_#{$1}"

      else 'unknown'
      end
    end

    # Scope for calculations, assumes entities as default
    def scope(conditions = [])
      conditions = [] if !conditions || !conditions.is_a?(Array)

      return Query.new(self, conditions)
    end

    def attr
      # config.attr? ? config.attr.to_sym : metric.to_sym
      metric.to_sym
    end

    def calc!
      @data = {}
      
      calculations.each do |calc, conds|
        conds.each do |cond|
          @result = scope(cond).calc(calc, attr)
          _data = @result
          _data = {cond.collect{|c| condition_key(c)}.join('_').to_sym => _data} if cond.is_a?(Array) && cond.any?

          if @data[calc]
            # Just making sure.. in case someone passed a calc with no conds
            # twice.. (e.g. apm(avg,avg))
            _data = {:default => _data} if !_data.is_a?(Hash)

            @data[calc] = (@data[calc].is_a?(Hash) ? @data[calc] : {:default => @data[calc]}).merge(_data)
          else
            @data[calc] = _data
          end
        end
      end
    end

    def done?
      !@data.nil?
    end

    def to_sym
      metric.to_sym
    end

    def to_hash
      calc! if !done?
      @data
    end
  end
end