require 'spec_helper'

describe ESDB::API do
  before(:all) do
    @identity = FactoryGirl.create(:sc2_identity)
    15.times { @identity.add_entity(FactoryGirl.build(:sc2_match_entity)) }
  end

  def app
    ESDB::API
  end
  
  describe "GET /identities" do
    it 'should return only identities with the specified :game_type' do
      identity = FactoryGirl.create(:sc2_identity, current_highest_type: '2v2', current_highest_league: 3, current_highest_leaguerank: 35)

      get "/v1/identities?game_type=2v2", :format => :json
      json = JSON.parse(last_response.body)

      json['collection'].count.should == 1
      json['collection'][0]['id'].should == identity.id
      json['collection'][0]['current_highest_type'].should == '2v2'
    end
  end

  # Note: StatBuilder should be tested elsewhere, but for completeness, we'll
  # include tests that test its implementation here too.
  #
  # Update: it is now being tested in stat_builder_spec, with grammer being
  # tested in citrus_spec as well.
  describe "GET /stats" do
    # I currently consider the source= param deprecated, for current purposes
    # using /identities/:id?stats= should be enough. Will decide source=s
    # future later on.

    it 'should return average apm only for the given identities' do
      # Give a new identity one entity with a precise apm number for this..
      identity = FactoryGirl.create(:sc2_identity)
      identity.add_entity(FactoryGirl.build(:sc2_match_entity, apm: 1911))

      get "/v1/stats?source=#{identity.id}&stats=apm(avg)", :format => :json
      
      json = JSON.parse(last_response.body)

      json.keys.should include(identity.id.to_s)
      json[identity.id.to_s].keys.should include('apm')
      json[identity.id.to_s]['apm'].keys.should include('avg')
      json[identity.id.to_s]['apm']['avg'].should == 1911
    end

    it 'should return stats described by StatsParam grammar' do
      get "/v1/stats?source=#{@identity.id}&stats=wpm(avg,mavg),apm(avg,mavg)", :format => :json
      
      json = JSON.parse(last_response.body)

      json.keys.should include(@identity.id.to_s)
      json[@identity.id.to_s].keys.should include('apm')
      json[@identity.id.to_s]['apm'].keys.should include('avg', 'mavg')

      json[@identity.id.to_s].keys.should include('wpm')
      json[@identity.id.to_s]['wpm'].keys.should include('avg', 'mavg')
    end

    it 'should compute moving averages correctly when the input numbers are all the same' do
      identity = FactoryGirl.create(:sc2_identity)
      15.times { identity.add_entity(FactoryGirl.build(:sc2_match_entity, wpm: 2.0)) }

      get "/v1/stats?source=#{identity.id}&stats=wpm(avg,mavg)", :format => :json

      json = JSON.parse(last_response.body)

      json.keys.should include(identity.id.to_s)
      json[identity.id.to_s].keys.should include('wpm')
      json[identity.id.to_s]['wpm'].keys.should include('avg', 'mavg')
      json[identity.id.to_s]['wpm']['avg'].should == 2.0
      json[identity.id.to_s]['wpm']['mavg'].should == 15.of { 2.0 }
    end    

    it 'should compute moving averages correctly when the input numbers are linearly increasing' do
      identity = FactoryGirl.create(:sc2_identity)
      15.times {|x| identity.add_entity(FactoryGirl.build(:sc2_match_entity, wpm: x+1)) }

      get "/v1/stats?source=#{identity.id}&stats=wpm(avg,mavg)", :format => :json

      json = JSON.parse(last_response.body)

      json.keys.should include(identity.id.to_s)
      json[identity.id.to_s].keys.should include('wpm')
      json[identity.id.to_s]['wpm'].keys.should include('avg', 'mavg')
      json[identity.id.to_s]['wpm']['avg'].should == 8.0

      # the first 1 is just 1.  after that they increase by 0.5 as each new number is added.
      # when there are 10, they average to 5.5.  after that the window increases by 1.0
      # as everything shifts up by 1.0 each time.
      json[identity.id.to_s]['wpm']['mavg'].should == [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5]
    end    

    it 'should compute moving averages correctly when the input numbers are linearly increasing floats' do
      identity = FactoryGirl.create(:sc2_identity)
      15.times {|x| identity.add_entity(FactoryGirl.build(:sc2_match_entity, wpm: x+1.5)) }

      get "/v1/stats?source=#{identity.id}&stats=wpm(avg,mavg)", :format => :json

      json = JSON.parse(last_response.body)

      json.keys.should include(identity.id.to_s)
      json[identity.id.to_s].keys.should include('wpm')
      json[identity.id.to_s]['wpm'].keys.should include('avg', 'mavg')
      json[identity.id.to_s]['wpm']['avg'].should == 8.5

      # the first 1 is just 1.5.  after that they increase by 0.5 as each new number is added.
      # when there are 10, they average to 6.0.  after that the window increases by 1.0
      # as everything shifts up by 1.0 each time.
      json[identity.id.to_s]['wpm']['mavg'].should == [1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0]
    end    

    it 'should compute moving averages correctly when some numbers are null' do
      identity = FactoryGirl.create(:sc2_identity)
      6.times {|x|
        identity.add_entity(FactoryGirl.build(:sc2_match_entity, wpm: x+1.5));
        identity.add_entity(FactoryGirl.build(:sc2_match_entity, wpm: nil))
      }

      get "/v1/stats?source=#{identity.id}&stats=wpm(avg,mavg)", :format => :json

      json = JSON.parse(last_response.body)

      json.keys.should include(identity.id.to_s)
      json[identity.id.to_s].keys.should include('wpm')
      json[identity.id.to_s]['wpm'].keys.should include('avg', 'mavg')
      json[identity.id.to_s]['wpm']['avg'].should == 4.0

      json[identity.id.to_s]['wpm']['mavg'].should == [1.5, 1.5, 2.0, 2.0, 2.5, 2.5, 3.0, 3.0, 3.5, 3.5, 4.5, 4.5]
    end    

    # Averages for boolean values ..I think I'm braindead. But I'll leave it
    # because it actually works fine by default with Sequel since we're using
    # an INT for win/loss.. I might have overseen something here though.
    # "FIXME" give it a thorough check.
    it 'should compute averages for booleans' do
      identity = FactoryGirl.create(:sc2_identity)

      entities = []
      [ true, false, true ].each do |won|
        identity.add_entity(FactoryGirl.build(:sc2_match_entity, win: won))
      end

      get "/v1/stats?source=#{identity.id}&stats=win(avg,mavg)", :format => :json

      json = JSON.parse(last_response.body)

      json.keys.should include(identity.id.to_s)
      json[identity.id.to_s].keys.should include('win')
      json[identity.id.to_s]['win'].keys.should include('avg', 'mavg')
      json[identity.id.to_s]['win']['avg'].should == 0.6667
      json[identity.id.to_s]['win']['mavg'].should == [1.0, 0.5, 0.67]
    end    
  end
end
