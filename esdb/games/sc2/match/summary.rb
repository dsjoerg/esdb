class ESDB::Sc2::Match
  class Summary < Sequel::Model(:esdb_sc2_match_summaries)

    many_to_one :identity, :class => 'ESDB::Sc2::Identity'
    many_to_one :match, :class => 'ESDB::Match'
#    one_to_many :entity_summaries, :class => 'ESDB::Match::EntitySummary'
    many_to_one :mapfacts, :class => 'ESDB::Sc2::Match::Summary::Mapfacts'

    subset :processed, ~{:processed_at => nil}

    # 
    # league field:
    #
    # post-20121231, this is the current 1v1 league of the identity
    #  that was retrieved.  this should rarely be null therefore, only
    #  when we are scraping for an identity that has no 1v1 league.
    #
    # from 20121124 to 20121230, it was the highest-ever 1v1 league of
    #  the identity that was retrieved, but often NULL because that
    #  field was not reliably being populated.
    #
    # pre-20121124, it was the highest-ever 1v1 league of
    #  the identity that was retrieved.
    #

    #
    # identity field:
    #
    # retrieved identity for hashes scraped for the indicated account
    # null for leaguemate scrapes
    #

    class Mapfacts < Sequel::Model(:esdb_sc2_match_summary_mapfacts)
    end

    # Enqueue the processing and parsing job
    def enqueue!(is_important)
      if is_important
        queue = 'python'
      else
        queue = 'python-low'
      end
      Resque::Job.create(queue, 'ggtracker.jobs.ParseSummary', {:hash => s2gs_hash, :gateway => gateway})
    end
    
    # Has the s2gs already been processed (parsed)?
    def processed?
      processed_at ? true : false
    end

    def failed?
      state.present? && state == "failed"
    end

    def depot_url
      "http://#{ESDB::Sc2.gateway_depot_host(gateway)}/#{s2gs_hash}.s2gs"
    end

    # Note: both identity and league are "best guess" - the s2gs_client can not
    # actually be sure that the hases it sends are from the requested identity and
    # therefor we also can not be 100% sure the league is correct.
    def postprocess!
    end

    def to_builder(options = {})
      builder = options[:builder] || jbuilder(options)
      builder.(self, :id, :gateway, :match_id, :mapfacts_id, :identity_id, :league)
      builder
    end
  end
end
