# Post-processing for replays, enqueued by the python replay parser
#

module ESDB::Jobs
  module Sc2::Replay
    class PostParse < ESDB::Job
      extend Resque::Plugins::JobStats
      @durations_recorded = 1000

      @queue = :replays

      def self.on_failure(exception, options)
        # Is there a replay?
        replay = ESDB::Sc2::Match::Replay.order(:id).last(:md5 => options['hash'])

        # And a provider?
        provider = Provider[options['provider_id']]

        # Then a failure callback is in order.
        provider.callback(:replay_error, {:job => options['uuid']}) if provider
      end

      def self.perform(options)

        postparse_received_at = Time.now

        replay = ESDB::Sc2::Match::Replay.order(:id).last(:md5 => options['hash'])
        raise Exception.new("Replay parser failure/no replay") if !replay

        # Get Provider, if passed to this job
        if options['provider_id'].present?
          provider = Provider[options['provider_id']]
        end

        if replay.match # TODO: Match matching query does not exist? What?
          ident_ids = []

          replay.match.accumulate!(replay)

          replay.match.entities.each do |entity|

            entity.compute_saturation_skill
            if entity.summary.present?
              entity.spending_skill = entity.summary.spending_skill
            end
            entity.save_changes

            identity = entity.identities.first
            identity.enqueue!

            # ident_ids is reported back to the JS frontend so that it
            # can decide which page to show, perhaps a player page,
            # after uploading is done.
            #
            # We do not want AI identities to be considered in the
            # computation. So we don't include them in ident_ids.  We
            # can tell if an identity is an AI because its bnet_id is
            # 0.
            #
            if (identity.bnet_id && identity.bnet_id != 0)
              ident_ids.push(identity.id)
            end
          end
        end

        postparse_complete_at = Time.now

        callback_hash = {
          :job => options['uuid'],
          :progress => 100,
          :status => 'Done',
          :match_id => replay.match.id,
          :ident_ids => ident_ids,
          :md5 => replay.md5,
          :ggtracker_received_at => options['ggtracker_received_at'],
          :esdb_received_at => options['esdb_received_at'],
          :preparse_received_at => options['preparse_received_at'],
          :jobspy_received_at => options['jobspy_received_at'],
          :jobspy_done_at => options['jobspy_done_at'],
          :postparse_received_at => postparse_received_at.to_f,
          :postparse_complete_at => postparse_complete_at.to_f
        }
        provider.callback(:replay_progress, callback_hash) if provider

        Resque::Job.create(:'replays-low', 'ESDB::Jobs::Sc2::Replay::PostPostParse', options)
      end
    end
  end
end
