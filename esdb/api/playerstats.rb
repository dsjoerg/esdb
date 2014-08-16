class ESDB::API
  resource :playerstats do

    # GET playerstats/:id

    desc 'Get stats for player#show'

    params do
      requires :id, :type => Integer, :desc => 'player ID'
    end

    get ':id' do
      identity = ESDB::Identity[params[:id]]
#      ESDB::PlayerStats.chartstats(identity, Jbuilder)
      Jbuilder.encode { |json|
        ESDB::PlayerStats.sumstats(identity, json)
      }
    end
  end
end