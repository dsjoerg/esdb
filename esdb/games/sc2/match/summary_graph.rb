class ESDB::Match::SummaryGraph < Sequel::Model(:esdb_sc2_match_summary_graph)

  one_to_many :graphpoints, :key => :graph_id, :class => 'ESDB::Match::GraphPoint'

  class ESDB::Match::GraphPoint < Sequel::Model(:esdb_sc2_match_summary_graphpoint)
    many_to_one :summary_graphs, :key => :graph_id, :class => 'ESDB::Match::SummaryGraph'
  end

  def to_builder(options = {})
    builder = options[:builder] || jbuilder(options)

    builder.array!(graphpoints) {|builder, graphpoint|
      builder.array! [ graphpoint.graph_seconds / 60.0, graphpoint.graph_value ]
    }
  end
end
