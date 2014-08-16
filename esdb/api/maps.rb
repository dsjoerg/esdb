# This is another endpoint that might be SC2 specific - we should probably
# have a SC2 namespace. TODO'ish

class ESDB::API
  resource :maps do
    desc 'Retrieve Maps'
    
    params do
      optional :identity_id,     type: Integer,
        desc: 'An identity for which the list of maps will be restricted.'
    end
    
    get '/names' do
      if params[:identity_id]
        themaps = ESDB::Sc2::Map
        themaps = themaps.join(:esdb_matches, :map_id => :id)
        themaps = themaps.join(:esdb_sc2_match_entities, :match_id => :id)
        themaps = themaps.join(:esdb_identity_entities, :entity_id => :id)
        themaps = themaps.where(:identity_id => params[:identity_id])
        themaps = themaps.distinct.select(:name)

#
# This code works, but there's no point activating it until esdb issue
#  #146 is addressed -- no point in listing maps that, if clicked,
#  won't return any results!
#
#        themaps2 = DB[:esdb_sc2_match_summary_mapfacts]
#        themaps2 = themaps2.join(:esdb_sc2_match_summaries, :mapfacts_id => :id)
#        themaps2 = themaps2.join(:esdb_sc2_match_entities, :match_id => :match_id)
#        themaps2 = themaps2.join(:esdb_identity_entities, :entity_id => :id)
#        themaps2 = themaps2.where(:esdb_identity_entities__identity_id => params[:identity_id])
#        themaps2 = themaps2.distinct.select(:map_name___name)
#        maps_names = themaps.union(themaps2).order(:name).all

        maps_names = themaps.order(:name).all
      else
        themaps = ESDB::Sc2::Map
        maps_names = themaps.distinct.order(:name).select(:name).all
      end

      Jbuilder.encode { |builder| builder.array!(maps_names) {|builder, map| map.to_builder(builder: builder)}  }
    end

    # Update Map (only for uploading map images currently)
    #
    # POST a single map image to this endpoint. The filename must be
    # mapname.tga, for example 'Daybreak LE.tga'
    #
    # The map image will be attached to ONE of the Maps with this
    # name, doesnt matter which one.
    #
    # The rest of ESDB is smart about finding this map image and using
    # it appropriately.
    #
    post '/image' do
      # image filename = 'Daybreak LE.tga', we want imagename = 'Daybreak LE'
      imagename = params[:image].filename.split('.')[0]

      maps_with_name = ESDB::Sc2::Map.where(:name => imagename)
      map = maps_with_name.first
      if map.present?
        map.image = params[:image]
        map.save!
        map.to_builder
      end
    end

  end
end