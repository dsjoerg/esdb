require 'spec_helper'

describe ESDB::AggregateStat do
  describe :recalc! do
    it 'should complete with no data' do
      AggregateStat.recalc!.should == true
    end
    
    # TODO: add specs with data!
  end
end
