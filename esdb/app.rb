class ESDB::App < Sinatra::Base
  get '/' do
    'Hello world!'
  end

  # Status of the API, Systems, etc?
  # Very crude collection of things I often look at.

  get '/status' do
    erb :status
  end

  get '/queue' do
    erb :queue
  end

  get '/limits' do
    erb :limits
  end

  get '/show_208' do
    erb :show_208
  end

  get '/mu-3a3f1ed3-7eba3187-8180d5c5-395096ce' do
    '42'
  end  

  get '/playtime' do
    erb :dj_playtime
  end
end
