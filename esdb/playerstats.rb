class ESDB::PlayerStats

  def self.chartstats(identity, builder)
    columns_to_select = [:apm, :wpm, :win, :summary__resource_collection_rate, :summary__average_unspent_resources, :match__duration_seconds]
    entity_columns_to_show = [:apm, :wpm, :win]
    summary_columns_to_show = [:resource_collection_rate, :average_unspent_resources]
    dataset = identity.entities_dataset
    dataset = dataset.eager_graph(:summary)
    dataset = dataset.eager_graph(:match).order(Sequel.send('desc', Sequel.qualify(:match, :played_at)))
    dataset = dataset.select(*columns_to_select)
    results = dataset.all
    # TODO get the match duration!! not working yet.
    # TODO turn win into 0/100
    # TODO apply windowing here or in JS?
    builder.encode { |json|
      entity_columns_to_show.each { |column|
        json.set!(column, results.collect {|entity| entity[column]})
      }
      summary_columns_to_show.each { |column|
        json.set!(column, results.collect {|entity|
          if entity.summary.nil?
            nil
          else
            entity.summary[:resource_collection_rate]
          end
        })
      }
      json.set!(:duration_seconds, results.collect {|entity|
        if entity.match.nil?
          puts "entity has no match, wtf!"
          nil
        else
          entity.match[:duration_seconds]
        end
      })
    }
  end

  def self.sumstats(identity, json)
    hours_played = identity.matches_dataset.sum(:duration_seconds).to_f / 3600.0
    json.hours_played hours_played
  end
end
