# Pre-processing for replays, enqueues python replay parser job
#
# Reactivated 20121210 because resque can do round-robining and pyres
# cant.
#

module ESDB::Jobs
  module Sc2::Replay
    class PreParse < ESDB::Job
      extend Resque::Plugins::JobStats
      @durations_recorded = 1000

      @queue = :replays

      def self.on_failure(exception, options)
        # Is there a replay?
        md5 = options['hash']
        replay = ESDB::Sc2::Match::Replay.order(:id).last(:md5 => md5)

        # And a provider?
        provider = Provider[options['provider_id']]

        # Then a failure callback is in order.
        provider.callback(:replay_error, {:job => options['uuid']}) if replay && provider
      end

      def self.perform(options)
        preparse_received_at = Time.now

        # Queue up the replay parser
        parser_id = Resque::Job.create('python', 'ggtracker.jobs.ParseReplay', {
          :uuid => options['uuid'],
          :hash => options['hash'],
          :ggtracker_received_at => options['ggtracker_received_at'],
          :esdb_received_at => options['esdb_received_at'],
          :preparse_received_at => preparse_received_at.to_f,
          :channel => options['channel'],
          :provider_id => options['provider_id']
        })
          
      end
        
    end
  end
end
