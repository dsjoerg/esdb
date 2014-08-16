require 'spec_helper'

# TODO: add job tests, add test redis instance

describe ESDB::API do
  def app
    ESDB::API
  end

  before(:each) do
    @replay_file = File.new(File.join(ESDB.root, 'spec/files/test.SC2Replay'))

    stub_request(:any, /amazonaws.com/).to_return(:status => 200, :body => '')
  end
  
  describe "POST /replays" do
    it 'should return error if no file given' do
      post '/v1/replays', :format => :json

      last_response.should_not be_ok
      last_response.body.should_not be_empty
      JSON.parse(last_response.body).should == {'status' => 'error', 'error' => 'File missing'}
    end

    it 'should return processing job id on success' do
      post '/v1/replays', :file => Rack::Test::UploadedFile.new(@replay_file), :format => :json

      last_response.status.should == 201 # created
      last_response.body.should_not be_empty

      json = JSON.parse(last_response.body)
      json.keys.should include('job')
      json['job'].length.should == 32
    end
  end
end