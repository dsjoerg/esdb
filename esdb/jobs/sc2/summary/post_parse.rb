# Top-level s2gs processing job, chains and waits for all dependent jobs
# to finish.

module ESDB::Jobs
  module Sc2::Summary
    class PostParse < ESDB::Job
      extend Resque::Plugins::JobStats
      @durations_recorded = 1000

      @queue = :summaries

      def self.perform(options)
        # FIXME: Confirm everything went smooth and if not bubble up the failure

        summary = ESDB::Sc2::Match::Summary.find(:s2gs_hash => options['hash'])

        if summary.processed_at.present?

          # its important that we set the matchs gateway before attempting to compute
          # spending skill, because the spending skill computation needs to know the gateway.
          #
          # TODO move the gateway-setting into ggpyjobs?
          #
          if summary.match.gateway.nil?
            summary.match.gateway = summary.gateway
            summary.match.save_changes
          end

          # Enqueue scraping for all identities associated with the s2gs
          summary.match.identities.each do |identity|
            # do we want to do any kind of identity.accumulate! ?
            # it's tricky.  No is easier.
            identity.enqueue!
          end unless !summary.match

          summary.match.entities.each do |entity|
            if entity.summary.present?
              entity.spending_skill = entity.summary.spending_skill
              entity.save_changes
            else
              puts "Entity with no summary! wtf entity.id = #{entity.id}"
            end
          end

          # Call postprocess! for the match to update sum caches
          summary.match.postprocess! if summary.match

        else

          summary.state = "failed"
          summary.save_changes

        end
      end
    end
  end
end
