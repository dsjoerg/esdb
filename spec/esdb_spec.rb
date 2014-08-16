require 'spec_helper'

describe ESDB::App do
  def app
    ESDB::App
  end

  it 'says hello world!' do
    get '/'
    last_response.should be_ok
    last_response.body.downcase.should == 'hello world!'
  end
end
