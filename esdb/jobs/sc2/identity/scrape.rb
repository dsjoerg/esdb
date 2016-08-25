module ESDB::Jobs
  module Sc2::Identity
    class Scrape < ESDB::Job
      include Resque::Plugins::Status
      extend Resque::Plugins::JobStats
      @durations_recorded = 1000

      # include Resque::Plugins::UniqueJob
      @queue = :scraping

      # Unset the scrape job ID after perform
      # TODO: will this also be called on failure?
      # we might want the job id sticking around after failure..
      def self.after_perform(job, options)
        identity = ESDB::Sc2::Identity.find(:id => options['identity_id'])
        identity.scrape_job_id = nil
        identity.save_changes
      end

      # how the fuck does this work when options isnt defined as an argument
      def perform
        at(1, 100, "Starting up..")

        identity = ESDB::Sc2::Identity.find(:id => options['identity_id'])

        if identity.scrape!(options['source'])
          # Postprocessing
          identity.postscrape!

          # after_perform also does this, but we need it before the callback
          identity.scrape_job_id = nil
          identity.save_changes

          # If successful - send callbacks to all providers
          # Now sends the entire object instead of just the identifying info
          identity.providers.each do |provider|
            if provider.present?
              provider.callback(:identity_update, identity.to_builder.attributes!)
            end
          end
        else
          ESDB.log("Scraping failed for identity #{identity.id}")

          # scraping failure is acceptable. for example, and identity
          # without a name is scrapable from sc2ranks, but they have
          # rate limits and we haven't built batch-retrieval yet.
        end
        
        at(100, 100, "Done")
      end
    end
  end
end
