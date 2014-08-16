# A "SQL Builder" for our "query resolving"
#
# The checks for handling are absolute here - it is not responding with vs_race
# if vs_race is only one of many conditions.
#
# So if we want [">z", ">20m"] for example, we need to add a method called
# after_minute_vs_race (alphabetically sorted keys from CONDREG)
class ESDB::StatBuilder::Query
  class SQLBuilder
    attr_accessor :dataset, :base

    def initialize(*args); end

    # It checks all conditions against CONDREG and collects the keys that 
    # match.
    def conditions_keys(conditions)
      condregs = conditions.collect do |cond|
        cr = ESDB::StatBuilder::Query::CONDREG.select {|n,r| cond.match(r) ? true : false }
        cr.collect{|c| c[0]}
      end.flatten || []
      condregs.sort
    end

    # Returns defined methods for the given conditions, hashbanged!?
    def conditions_methods(conditions)
      keys = conditions_keys(conditions)
      keys.reject{|k| !self.respond_to?("#{k}!")}
    end

    def can_handle?(conditions)
      return false if !conditions.empty? && conditions_methods(conditions).empty?
      true
    end

    # ClassMethods
    class << self

      # Parses the conditions into a hash using CONDREG
      def parsed_conditions(conditions)
        _parsed = {}
        for cond in conditions do
          match = ESDB::StatBuilder::Query::CONDREG.select {|n,r| cond.match(r)}.to_a.flatten
          _parsed[match[0]] = cond.scan(match[1]).flatten[0]
        end
        _parsed
      end

      def create(conditions, options = {})
        instance = self.new(conditions, options)
        stat = options[:stat]

        if instance.can_handle?(conditions)
          options.merge!(parsed_conditions(conditions))

          # If a custom scope/dataset has been given to the associated 
          # StatBuilder, honor it.
          if stat.stat_builder.options.dataset
            instance.dataset = stat.stat_builder.options.dataset
            instance.base = instance.dataset.model
          else
            instance.base = ESDB::Sc2::Match::Entity
            instance.dataset = instance.base.dataset
          end

          # We really only want entities back - a join gone wrong can translate
          # to the wrong object for some reason. (Sequel bug, or are we indeed
          # relying too much on "sequel magic" and this is really needed?)
          instance.dataset = instance.dataset.select(Sequel.qualify(Sc2::Match::Entity.table_name, '*'.lit))

          # TODO: maybe have cleaner way to pass identity as a condition?
          # This seems hacky, :stat is passed by Query#sql which in turn is
          # passed self by Stat's constructor.. 
          instance.as_identity!(nil, {:as_identity => stat.identity.id}) if stat && stat.identity

          # Calls all condition methods successively, chaining on the dataset
          instance.conditions_methods(conditions).each do |method|
            instance.send("#{method}!", conditions, options)
          end
        else
          
          raise "One or more condition methods (in #{instance.conditions_keys(conditions)}) are not defined."
        end

        instance
      end
    end

    # Condition Methods (Instance)
    #
    # These methods are modifying the dataset to only include a collection
    # for given conditions.

    # Limit dataset results to rows played by a given identity
    #
    # This is a good example of something that looks generic but will fall
    # apart once we're not just using Entity as a base.. (FIXME)
    def as_identity!(conditions, options = {})
      tbl = base.table_name
      ietbl = ESDB::IdentityEntity.table_name.as(@dataset.unused_table_alias(:ie))
      idtbl = ESDB::Identity.table_name.as(@dataset.unused_table_alias(:id))

      @_as = true;

      @dataset = @dataset.
        # select(Sequel.qualify(tbl, '*'.lit)).
        inner_join(ietbl, [
          {"#{ietbl.aliaz}__entity_id".to_sym => "#{tbl}__id".to_sym}
        ]).
        inner_join(idtbl, [
          {"#{ietbl.aliaz}__identity_id".to_sym => "#{idtbl.aliaz}__id".to_sym}
        ]).
        where("#{idtbl.aliaz}__id".to_sym => options[:as_identity])
    end

    # Limit dataset results to rows played against a given identity
    def vs_identity!(conditions, options = {})
      tbl = base.table_name
      jt = tbl.as(:t)

      itbl = ESDB::IdentityEntity.table_name.as(@dataset.unused_table_alias(:ie))
      
      @dataset = @dataset.
        # select(Sequel.qualify(tbl, '*'.lit)).
        inner_join(jt, [
          {"#{tbl}__match_id".to_sym => :t__match_id},
          ~{"#{tbl}__id".to_sym => :t__id}
        ]).
        inner_join(itbl, [
          {"#{itbl.aliaz}__entity_id".to_sym => :t__id, "#{itbl.aliaz}__identity_id".to_sym => options[:vs_identity]}
        ])
    end

    # Limit dataset results to rows played as a given race

    # TODO: what's below has been added primarily for matches.rb filter, where
    # we want to be able to send either/or vs/as_race to filter.

    # Here's my thought process on race vs race:
    # If we only get a "vs race", it really doesn't matter which team or player 
    # played that race. If we however get other "as" criteria, identity or race
    # the "vs race" may only be the race played by opponents of the entities 
    # that are selected by them.
    # I just quickly added @_as that is set for this purpose.
    # If it is set, we'll use opponent_race!

    def where_race!(race)
      tbl = base.table_name
      @dataset = @dataset.where("#{tbl}__race".to_sym => race)
    end

    def opponent_race!(conditions, options = {})
      race = options[:vs_race] || options[:as_race]
      tbl = base.table_name
      jt = tbl.as(:t)

      @dataset = @dataset.inner_join(jt, [
        {"#{tbl}__match_id".to_sym => :t__match_id, :t__race => race},
        ~{"#{tbl}__id".to_sym => :t__id, "#{tbl}__team".to_sym => :t__team}
      ])
    end

    # Limit dataset results to rows played against a given race
    def vs_race!(conditions, options = {})
      return opponent_race!(conditions, options) if @_as
      @race = options[:vs_race] || options[:as_race]
      @_as = true
      where_race!(@race)
    end

    def as_race!(*args)
      vs_race!(*args)
    end

    # In league (range)
    def in_league!(conditions, options = {})
      leagues = options[:in_league].split('-').collect(&:to_i)

      if leagues.size == 2
        @dataset = @dataset.where('highest_league >= ? AND highest_league <= ?', leagues[0], leagues[1])
      else
        @dataset = @dataset.where(:highest_league => leagues[0])
      end
    end

    # The methods below either do not need to modify the dataset or are not
    # implemented yet.

    def not!(conditions, options = {})
      @dataset
    end

    def extra!(*args)
      @dataset
    end
  end
end