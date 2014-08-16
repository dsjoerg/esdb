# Post-post-processing for replays, enqueued by post_parse
#

module ESDB::Jobs
  module Sc2::Replay
    class PostPostParse < ESDB::Job
      extend Resque::Plugins::JobStats
      @durations_recorded = 1000

      @queue = :'replays-low'

      def self.perform(options)
        replay = ESDB::Sc2::Match::Replay.order(:id).last(:md5 => options['hash'])
        if options['provider_id'].present?
          replay.providers << Provider[options['provider_id']]
        end
        replay.postprocess!

        if replay.match
          replay.match.postprocess!
          replay.match.entities.each do |entity|
            identity = entity.identities.first
            identity.full_accumulate!
          end
        end
      end
    end
  end
end
