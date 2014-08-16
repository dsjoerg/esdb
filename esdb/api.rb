class ESDB::API < Grape::API
  enable :raise_errors

  version 'v1'

  # Caching using the garner gem
  use Garner::Middleware::Cache::Bust
  helpers Garner::Mixins::Grape::Cache

  # "Oauth2 Authentication", faked for now, primarily for Provider 
  # identification.
  #
  # Note: something to consider is that there will later be a distinction
  # between Providers, client applications and other entities that need access
  # to the API. This is very basic as of now.
  #
  # TODO: might want to support user authentication too, which I'd rather call
  # "access_token" than this. This could be renamed to "api_key" or whatever.
  before do |endpoint|
    if access_token = params.delete(:access_token)
      # we only support the ggtracker provider right now

      # doing it this way we dont have to hit the database on every
      # single API call to retrieve the current providers

      # on the night of 20130531 I had a horrible stupid problem where
      # the access token wasnt being loaded properly by all unicorn
      # threads. it was causing replay uploads to randomly rail.
      #
      # rather than debug it further, i did this.
      #

      if access_token != ESDB.api_key
        $stderr.puts "EXPECTED #{ESDB.api_key}, saw #{access_token}"
        error!('Invalid Access Token') 
      end
      @provider = Provider.ggt_provider
    end

    # We only really care about JSON right now, so let's force the Content-Type
    content_type 'application/json'

    # Parse the "fields" param
    params[:filter] = params[:filter] ? ApiFields::Parser.parse(params[:filter]) : ApiFields::Blank.new
  end

  helpers do
    def current_provider
      @provider
    end
  end

  # TODO refactor this code to be a '/matches' endpoint instead.  DJ
  # was going to kill this code, but Marian said keep it on 20120918
  desc 'Retrieve replays index'
  get '/replays' do
    stat = ESDB::StatBuilder::Stat.new(:metric => "duration", :calculations => ["count"])
    query = ESDB::StatBuilder::Query.new(stat, (params[:query] || '').split(","))
    entities = query.collection

    replays = entities.replays.first(10, :order => [:played_at.desc])
    results = replays.collect{ |replay|
      result = {:played_at => replay.played_at}
      ents = replay.entities
      result[:player1] = ents[0].identities.first(:type => "ESDB::Provider::Identity")
      result[:player2] = ents[1].identities.first(:type => "ESDB::Provider::Identity")
      result[:player1_stats] = ents[0]
      result[:player2_stats] = ents[1]
      result
    }
    results.to_json
  end

  desc 'Retrieve statistics.', {
    :params => {
      :source => { :description => 'Single source identity' },
      :stats => { :description => 'StatsParam string, see StatsParam grammar' },
    }
  }
  get '/stats' do
    sb = ESDB::StatBuilder.new(params)
    sb.to_json
  end
end
