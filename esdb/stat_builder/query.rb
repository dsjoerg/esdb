# The "Query Resolver" for StatBuilder, a class that resolves conditions
# into either DataMapper chains or raw SQL where appropriate.
#
# This still uses DataMapper::Collection and our custom calculations

class ESDB::StatBuilder
  class Query
    attr_reader :conditions, :stat

    CONDREG = {
      :race         => /^<([a-zA-Z])$/,
      :vs_race      => /^>([a-zA-Z])$/,
      :as_identity  => /^<(\d+)$/,
      :vs_identity  => /^>(\d+)$/,
      :at_minute    => /^(\d+)m$/,
      :after_minute => /^>(\d+)m$/,
      :not          => /^\!(["\w\d]+)$/,
      :before_date  => /^<D(\d+)$/,
      :after_date   => /^>D(\d+)$/,
      :resolution   => /^M(\w)$/,
      :in_league    => /^L(\d[\-\d]*)$/,
      
      # Quick solution to passing an extra argument to a calc (for example,
      # window size to #mavg)
      :extra        => /^E(.*?)$/
    }

    def initialize(stat, conditions = [])
      @stat = stat
      @conditions = conditions
      @calc_conditions = {}
    end

    def sql(column = nil)
      sql_builder = SQLBuilder.create(conditions, :stat => @stat)
      sql_builder
    end

    # Pass calc methods to the SQLBuilder
    def calc(method, column)
      @sql = sql(column)

      if column.to_s =~ /minutes\./
        mtable = ESDB::Sc2::Match::Replay::Minute.table_name

        column = column.to_s.split('.').collect{|m| m.downcase.to_sym}
        column = column.last
        qualified_column = Sequel.qualify(mtable, column)

        #        puts "hi! #{@sql.dataset.sql}"

        _dataset = ESDB::Sc2::Match::Replay::Minute.
          inner_join(@sql.dataset, :id => :entity_id).
          select(Sequel.qualify(mtable, column[1].lit)).
          where{Sequel.qualify(mtable, :minute) > 0}.
          order(Sequel.qualify(mtable, :minute)).
          group(Sequel.qualify(mtable, :minute))

        # return _dataset.select(:minute, Sequel.function(method, qcol).as(qcol)).collect(&qcol).collect(&:to_f)

        return _dataset.send(method, qualified_column)
      else
        qualified_column = Sequel.qualify(@sql.base.table_name, column)
      end

      # Special cases of methods that are not "calculations" (methods on 
      # Dataset) are handled here.
      case method
      when :default, :all then
        @sql.dataset.all.collect(&column)
      else
        parsed_conditions = SQLBuilder.parsed_conditions(@conditions)
        if parsed_conditions[:extra]
          @sql.dataset.send(method, qualified_column, parsed_conditions[:extra])
        else
          @sql.dataset.send(method, qualified_column)
        end
      end
    end
  end
end