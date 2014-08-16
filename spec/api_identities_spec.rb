require 'spec_helper'

describe ESDB::API do
  def app
    ESDB::API
  end

  before(:all) do
    # Make sure there's some identities!
    3.times { FactoryGirl.create(:sc2_identity) }
  end

  describe "GET /identities/:id" do
    it 'should respond with 404 if the identity can not be found' do
      get '/v1/identity/1911', format: :json
      last_response.status.should == 404
    end
  end

  # Placeholder, at least execute it once. TODO
  describe "GET /identities" do
    it 'should be ok PH' do
      get "/v1/identities", format: :json

      last_response.should be_ok
      last_response.body.should_not be_empty
    end
  end
end