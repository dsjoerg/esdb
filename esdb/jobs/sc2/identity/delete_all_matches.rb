module ESDB::Jobs
  module Sc2::Identity
    class DeleteAllMatches < ESDB::Job
      include Resque::Plugins::Status
      extend Resque::Plugins::JobStats
      @durations_recorded = 1000

      @queue = :'replays-low'

      def self.perform(options)

        identity_id = options['identity_id'];
        ESDB.log("identity_id =  #{identity_id}")
        identity = ESDB::Sc2::Identity.find(:id => identity_id)
        ESDB.log("identity = #{identity}")
        identity.destroy_all_matches!
        
      end
    end
  end
end
