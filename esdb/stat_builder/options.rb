# This Options Class is a simple extension on Hash with some added sugar
# through Hashie for easy defaults and method access for StatBuilder

class ESDB::StatBuilder
  class Options < Hash
    include Hashie::Extensions::KeyConversion
    include Hashie::Extensions::MethodAccess

    def initialize(opts = {})
      merge!(opts)
      symbolize_keys!
      reverse_merge!({
        :source => nil,
        :identities => [],
        :summarize => false,

        # A custom scope (dataset) can be passed into StatBuilder, which will then
        # be used by SQLBuilder and all other components instead of picking the
        # the appropriate dataset automatically.
        :dataset => nil,

        :stats => nil
      })

      # if :source is present or stats is a string it's a clear indicator that
      # this is coming from an API request
      if source? || (stats? && stats.is_a?(String))
        self[:identities] = [source.to_i] if source?

        # Construct Array out of StatsParam data for use in StatBuilder
        #
        # TODO: make StatsParam nicer? Will we use it elsewhere?
        # e.g. I'd like to give StatsParam a Stat class, #stats, make it easily
        # walkable/usable instead of traversing the parser tree directly into
        # StatBuilder here.
        #
        # Note the "name.matches" array traversal - not elegant, let's patch
        # Citrus::Match? Same with the extraneous tree nodes..

        if stats.is_a?(String)
          sp = StatsParam.parse(self[:stats])
          # sp.dump

          ns = {}

          sp.matches.each do |m|
            stat = m.stat
            ns[stat.metric.to_sym] ||= {}

            # A stat can have no args (e.g., just "wpm") which will trigger 
            # default behavior. For simplicity within the code, we insert one
            # arg called 'default' for it.
            if !stat.args
              ns[stat.metric.to_sym][:default] ||= []
              ns[stat.metric.to_sym][:default] << true
            else
              stat.args.matches.each do |mm|
                arg = mm.first

                ns[stat.metric.to_sym][arg.calc.to_sym] ||= []
                ns[stat.metric.to_sym][arg.calc.to_sym] << (arg.conditions ? arg.conditions.to_a[1..-1].collect(&:condition) : true)
              end
            end

          end

          self[:stats] = ns
        end
      else
        self
      end
    end
  end
end