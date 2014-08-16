# This represents the replay file.

class ESDB::Sc2::Match
  class Replay < Sequel::Model(:esdb_sc2_match_replays)

    subset :processed, ~{:processed_at => nil}

    # Summarizing statistics within the replay every minute still seems like
    # a reasonable thing to do.
    #
    # TODO move this to be an inner class of Match instead of Replay
    # 
    class Minute < Sequel::Model(:esdb_sc2_match_replay_minutes)
    end

    many_to_one :match, :class => 'ESDB::Match'
    many_to_many :providers, :class => 'ESDB::Provider', :join_table => 'esdb_sc2_match_replay_providers'

    def reprocess!
      reprocess_received_at = Time.now

      uuid = Digest::MD5.hexdigest("#{self.md5}#{Time.now.to_f}")

      parser_id = Resque::Job.create('python-low', 'ggtracker.jobs.ParseReplay', {
                                       :uuid => uuid,
                                       :hash => self.md5,
                                       :ggtracker_received_at => reprocess_received_at.to_f,
                                       :esdb_received_at => reprocess_received_at.to_f,
                                       :preparse_received_at => reprocess_received_at.to_f,
                                       :provider_id => ''
                                     })
    end

    # Post-processing for replays
    def postprocess!
      # Update last_replay_played_at for all identities
      match.identities.each do |identity|
        # dont bother to update this for AI identities
        if identity.bnet_id != 0
          if !identity.last_replay_played_at || match.played_at - identity.last_replay_played_at > 60
            identity.update(:last_replay_played_at => match.played_at) 
          end
          identity.save_changes
        end
      end
    end

    # DJ 20120918 disabled the code that calls this function in
    # process.rb.  Marian, dont reactivate until we can have a chat
    # about it.  I expect we'll never have to.
    #        
    # TMP: assign primary provider identity associated with attached
    # battle.net identities on this replay.
    def guess_provider_identities!
      entities.each do |entity|
        entity.identities.all.each do |identity|
          # We just pick the first Provider::Identity off all entities the
          # identity has and assign that in good faith.
          provider_identity = identity.entities.identities.all(:type => 'ESDB::Provider::Identity').first
          begin
            entity.identities << provider_identity
            # entity.identity_entities.create(:identity => provider_identity)
            entity.save
          rescue
          end
        end
      end
    end

    # Constructs a valid S3 URL from current S3 configuration for this replay
    # TODO: not safe for europeans!
    def url
      "https://#{ESDB.s3cfg['replays']['bucket']}.s3.amazonaws.com/#{md5}.SC2Replay"

      # backwards compatibility hack.  On 20121211, DJ changed the md5 field to simply be the S3 Key.
      # hmm, actually lets not do this.
      # if (md5 =~ /.+sc2replay/i).nil?
        # old style
      # else
        # new style
      #  "https://#{ESDB.s3cfg['replays']['bucket']}.s3.amazonaws.com/#{md5}"
      # end
    end

    # Serialize to Jbuilder
    def to_builder(options = {})
      builder = options[:builder] || jbuilder(options)
      builder.(self, :id)
      if hidden == 0
        builder.md5(md5)
        builder.url(url)
      end
      builder
    end
  end
end
