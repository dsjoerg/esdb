require 'spec_helper'

describe ESDB::StatBuilder do
  before(:all) do
    # TODO: build a complete identity with all matchups, etc.
    # then update all specs below to reflect that (instead of simply checking
    # whether it ran at all check for accurate values)    
  
    @identity = FactoryGirl.create(:sc2_identity)
    15.times {
      @identity.add_entity(FactoryGirl.create(:sc2_match_entity, :wpm => 2.0, :win => 1))
    }

    @opponent = FactoryGirl.create(:sc2_identity)

    # Create 3 replays for @identity, with opponent playing each race
    #
    # TODO: isn't there a nicer syntax for this with Sequel? Do we really need
    # to chain #add_<association> calls?
    ['Z', 'P', 'T'].each do |race|
      replay = ESDB::Sc2::Match::Replay.make

      _entity = FactoryGirl.create(:sc2_match_entity)
      _entity.add_identity(@identity)
      replay.match.add_entity(_entity)
      
      _entity = FactoryGirl.create(:sc2_match_entity, :race => race)
      _entity.add_identity(@opponent)
      replay.match.add_entity(_entity)
    end

    # Used in specs that test for a boolean value not existing (losses)
    @winner = FactoryGirl.create(:sc2_identity)
    @winner.add_entity(FactoryGirl.create(:sc2_match_entity, :wpm => 2.0, :win => 1))
  end

  # See https://github.com/ggtracker/esdb/issues/36
  it 'should respect the order of its dataset' do
    dataset = ESDB::Sc2::Match::Entity.dataset.order(:id)
    sb = ESDB::StatBuilder.new(:stats => 'apm(mavg:[E1])', :dataset => dataset)
    sb.build!.should == true
    result = sb.to_hash[:apm][:mavg][:unknown]
    
    sb = ESDB::StatBuilder.new(:stats => 'apm(mavg:[E1])', :dataset => dataset.reverse_order)
    sb.build!.should == true
    reverse_result = sb.to_hash[:apm][:mavg][:unknown]

    reverse_result.should == result.reverse
  end

  it 'should properly populate Options#stats via StatsParam' do
    sb = ESDB::StatBuilder.new(:stats => 'apm(avg:[>z]),wpm(avg:[<p,a])')
    
    expected_hash = {
      :apm => {:avg => [[">z"]]}, 
      :wpm => {:avg => [["<p", "a"]]}
    }
    
    sb.options.stats.should be_a(Hash)
    sb.options.stats.should == expected_hash
  end

  it 'should merge multiple appearances of a calc and conditions correctly' do
    sb = ESDB::StatBuilder.new(:stats => 'apm(avg,avg:[>z])')
    
    expected_hash = {
      :apm => {:avg => [true, [">z"]]}, 
    }
    
    sb.options.stats.should be_a(Hash)
    sb.options.stats.should == expected_hash
  end

  it 'should return zero if a boolean value does not exist (no losses)' do
    sb = ESDB::StatBuilder.new(:source => @winner.id, :stats => 'loss(count)')
    
    # TODO: actual value tests!
    sb.build!.should == true

    sb.to_hash.keys.should include(@winner.id) # should include the winner
    sb.to_hash[@winner.id].keys.should include(:loss)
    sb.to_hash[@winner.id][:loss][:count].should == 0
  end

  # Testing Conditions
  # TODO: loop through Stats conditions instead of writing specs manually

  it 'should be able to calc avg apm versus another provider identity' do
    replay = ESDB::Sc2::Match::Replay.make

    2.times {
      _entity = FactoryGirl.create(:sc2_match_entity, :apm => 19.11, :win => 1)
      _entity.add_identity(FactoryGirl.create(:sc2_identity)) #(:entities => []),
      _entity.add_identity(ESDB::Provider::Identity.make) #(:entities => []),
      replay.match.add_entity(_entity)
    }

    left, right = replay.match.entities.identities.where(:type => 'ESDB::Provider::Identity').all.to_a

    # To make sure versus identity works correctly, give the left player 
    # another match against someone else with different APM
    FactoryGirl.create(:sc2_match_entity, :apm => 2.0).add_identity(left)

    sb = ESDB::StatBuilder.new(:identities => [left.id], :stats => "apm(avg:[>#{right.id}])")

    expected_hash = {
      :apm => {:avg => [[">#{right.id}"]]}, 
    }
    
    sb.options.stats.should be_a(Hash)
    sb.options.stats.should == expected_hash

    # TODO: actual value tests!
    sb.build!.should == true

    hash = sb.to_hash
    hash.keys.should include(left.id)

    ('%.2f' % sb.to_hash[left.id][:apm][:avg]["vs_identity_#{right.id}".to_sym].to_f).should == '19.11'
  end

  # Uses the replays set up for @identity playing vs @opponent as each race
  # in the setup.
  it 'should be able to calc avg apm versus race' do
    sb = ESDB::StatBuilder.new(:identities => [@identity.id], :stats => 'apm(avg:[>z])')
    expected_hash = {:apm => {:avg => [[">z"]]}}
    sb.options.stats.should be_a(Hash)
    sb.options.stats.should == expected_hash
    sb.build!.should == true
    apm1 = sb.to_hash[@identity.id][:apm][:avg][:vs_race_z].to_f
    apm1.should_not == 0.0

    # To compare, another race.. hacky
    
    sb = ESDB::StatBuilder.new(:identities => [@identity.id], :stats => 'apm(avg:[>p])')
    expected_hash = {:apm => {:avg => [[">p"]]}}
    sb.options.stats.should be_a(Hash)
    sb.options.stats.should == expected_hash
    sb.build!.should == true
    apm2 = sb.to_hash[@identity.id][:apm][:avg][:vs_race_p].to_f
    apm2.should_not == 0.0
    
    apm1.should_not == apm2
  end

  # Describe CONDREG in StatsParam
  describe 'StatsParam' do
    before(:all) do
      DatabaseCleaner.clean

      # Create two identities that only ever played against each other to
      # compare vs_/as_ data
      @identity1 = FactoryGirl.create(:sc2_identity)
      3.times {|i| @identity1.add_entity(FactoryGirl.build(:sc2_match_entity, :wpm => 2.0, :win => 1, :match_id => i)) }

      @identity2 = FactoryGirl.create(:sc2_identity)
      3.times {|i| @identity2.add_entity(FactoryGirl.build(:sc2_match_entity, :wpm => 2.0, :win => 0, :match_id => i)) }
    end

    # This fails currently! CLEANME
    describe 'vs_identity' do
      it 'should not return the apm of the given identitys entities' do
        sb = ESDB::StatBuilder.new(:stats => "apm(all:[>#{@identity1.id}])")
        sb.build!.should == true

        apm = sb.to_hash[:apm][:all]["vs_identity_#{@identity1.id}".to_sym]
        apm.should == @identity2.entities.collect(&:apm)
      end
    end
  end
end
