class ESDB::API
  resource :matches do

    # GET matches/:id

    desc 'Get match details'

    params do
      requires :id, type: String, desc: 'match ID or MD5 for a replay'

      optional :filter,     type: String,
        desc: 'The Param formerly known as the FieldsParam, filters output.'
    end

    get ':id' do
      # See if :id is an Integer to directly get the match..
      if params[:id].to_i.to_s == params[:id]
        dataset = ESDB::Match.where(id: params[:id])
        match = dataset.first

      # Or a string, with an Md5, for a replay..
      else
        replay = ESDB::Sc2::Match::Replay.where(md5: params[:id]).first
        if replay
          match = replay.match
          dataset = ESDB::Match.where(id: match.id)
        end
      end

      error!('Not Found', 404) if !match
      error!('Not Found', 404) if match.deleted?

      hash = match.to_builder(filter: params[:filter], provider: current_provider).attributes!
      hash.to_json
    end

    # GET matches

    desc 'Get matches'

    # TODO: make invalid paramters output valid JSON
    params do
      # Filters
      optional :game_type,  type: String, regexp: /^[\d\w]{3}$/, 
        desc: 'Game Type, 1v1, 2v2, FFA, etc.'
      optional :map_id,     type: Integer, desc: 'Map ID'
      optional :map_name,   type: String,  desc: 'Map name'
      optional :average_league, type: Integer, desc: 'Average league'
      optional :identity_id, type: Integer, desc: 'associated Identity ID'
      optional :replay,     type: Boolean, desc: 'Only return matches that have at least one replay'
      optional :paginate,   type: Boolean, desc: 'Compute the total number of matches so that full pagination information can be shown'
      optional :summary,    type: Boolean, desc: 'Only return matches that have at least one summary'
      optional :gateway,    type: String, desc: 'Only return matches played on the given gateway (must have a replay or summary)'
      optional :category,   type: String, desc: 'Only return matches with the given category (Ladder, Public, Private)'
      optional :race,       type: String, desc: 'Applies given race filter to all entities'
      optional :vs_race,    type: String, desc: 'Applies race filter to entities not matched by :race if given, acts like :race otherwise'
      optional :one_wins,   type: Boolean, desc: 'First player wins'
      optional :two_wins,   type: Boolean, desc: 'Second player wins'
      optional :unit_one,   type: String, desc: 'Type of unit player one has'
      optional :unit_two,   type: String, desc: 'Type of unit player two has'
      optional :time_one,   type: Integer, desc: 'Time at which player one has unit_one'
      optional :time_two,   type: Integer, desc: 'Time at which player two has unit_two'
      optional :unit_one_count,   type: Integer, desc: 'Number of that unit player one has at that time'
      optional :unit_two_count,   type: Integer, desc: 'Number of that unit player two has at that time'
      optional :limit,      type: Integer, desc: 'Limit (Default: 10)'
      optional :offset,     type: Integer, desc: 'Offset'
      optional :replay_after_dt,   type: Integer, desc: 'Earliest DateTime for results, as a UNIX timestamp'
      optional :sc2ranks,   type: Boolean, desc: 'Give results in sc2ranks format'
      optional :pack,       type: String, desc: 'Name of a replay pack to restrict to'
      optional :wcs,        type: Boolean, desc: 'Show only WCS matches'
      optional :page,       type: Integer, 
        desc: 'Instead of calculating the offset, you can pass limit (or leave it at the default) and a page instead'
      optional :order,      type: String, 
        desc: 'Field to order results by, preceded by a dash for ascending, underscore for descending'

      optional :filter,     type: String,
        desc: 'The Param formerly known as the FieldsParam, filter output. Defaults to exclude graph data and summaries.'
    end

    get '/' do

      thecachebinding = {bind: [[ESDB::Identity], [ESDB::Match]]}

      # queries that involve specific units are expensive, lets not
      # invalidate them just because something has updated with an
      # identity or we got a new match
      if params[:one_wins] || params[:two_wins] || params[:unit_one] || params[:unit_two]
        thecachebinding = {}
      end

      if params[:sc2ranks]
        # sc2ranks results are too big to cache. yay
        ESDB::Match.get_matches(params, current_provider)
      else
        cache(thecachebinding) do
          ESDB.log("cache miss for matches/, params=#{params.to_s}")
          ESDB::Match.get_matches(params, current_provider)
        end
      end
    end # get '/'


    # POST matches/:id/userdelete

    desc 'User deletion of the match. Doesnt actually delete the record but creates a user-deletion record.'

    params do
      requires :id, type: String, desc: 'match ID'
    end

    post ':id/userdelete' do
      if @provider  # access_token must be provided, see esdb/api.rb
        match = ESDB::Match[params[:id]]
        match_deleted = ESDB::Match_Deleted.create(:match => match,
                                                   :user_id => params[:user_id],
                                                   :deleted_at => Time.now)
        match_deleted.save!
        match.invalidate_cache!
        success!({})
      else
        ESDB.error("userdelete attempted but access_token unrecognized.")
      end
    end

  end # resource :matches
end # class ESDB::API
