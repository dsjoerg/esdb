require 'spec_helper'

describe ESDB::API do
  def app
    ESDB::API
  end

  before(:all) do
    # Make sure there's some matches!
    3.times { FactoryGirl.create(:match) }
  end

  describe "GET /matches/:id" do
    it 'should respond with 404 if the match can not be found' do
      get '/v1/matches/1911', format: :json
      last_response.status.should == 404
    end
  end

  describe "GET /matches" do
    it 'should return matches' do
      get '/v1/matches', format: :json

      last_response.should be_ok
      last_response.body.should_not be_empty

      json = JSON.parse(last_response.body)
      json.keys.should include('collection')
    end

    it 'should exclude entities if filter is match(-entities)' do
      get '/v1/matches', filter: 'match(-entities)', format: :json

      last_response.should be_ok
      last_response.body.should_not be_empty

      json = JSON.parse(last_response.body)
      match = json['collection'][0]
      match.keys.should_not include('entities')
    end

    it 'should exclude replays if filter is match(-replays)' do
      get '/v1/matches', filter: 'match(-replays)', format: :json

      last_response.should be_ok
      last_response.body.should_not be_empty

      json = JSON.parse(last_response.body)
      match = json['collection'][0]
      json.keys.should_not include('replays')
    end

    it 'should exclude replays, excessive entity information and graphs by default' do
      get '/v1/matches', filter: '-graphs,match(-replays),entity(-summary,-minutes,-armies)', format: :json

      last_response.should be_ok
      last_response.body.should_not be_empty

      json = JSON.parse(last_response.body)
      match = json['collection'][0]
      match.keys.should_not include('replays')

      match['entities'][0].keys.should_not include('summary')
      match['entities'][0].keys.should_not include('minutes')
      match['entities'][0].keys.should_not include('armies_by_frame')
    end

    it 'should have stats for matches when requested' do
      get '/v1/matches', stats: 'apm(avg)', format: :json

      last_response.should be_ok
      last_response.body.should_not be_empty

      json = JSON.parse(last_response.body)
      json.keys.should include('stats')
      
      json['stats'].keys.should include('apm')
    end

    it 'should NOT impose match order on the dataset for statbuilder' do
      identity = FactoryGirl.create(:sc2_identity)
      10.times { 
        match = FactoryGirl.create(:match)
        fe = match.entities.first
        fe.add_identity(identity)
        fe.save
      }

      get '/v1/matches', stats: "apm(mavg:[<#{identity.id},E1])", order: '-played_at', format: :json

      last_response.should be_ok
      last_response.body.should_not be_empty

      json = JSON.parse(last_response.body)
      json.keys.should include('stats')

      result = json['stats']['apm']['mavg']['as_identity_1_unknown']

      get '/v1/matches', stats: "apm(mavg:[<#{identity.id},E1])", order: '_played_at', format: :json

      json = JSON.parse(last_response.body)
      json.keys.should include('stats')

      second_result = json['stats']['apm']['mavg']['as_identity_1_unknown']
      
      second_result.should == result
    end
  end
end
