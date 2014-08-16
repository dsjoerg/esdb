class ESDB::API
  namespace :replays do

    desc 'Upload Replay File', {
      :params => {
        :file => { :description => 'content md5 hash -- must already be uploaded to S3' },
      }
    }
    post do
      esdb_received_at = Time.now

      error!('File missing') if !params[:file]

      hash = params[:file]

      # Compensating for the lack of a uuid when not using resque-status
      uuid = Digest::MD5.hexdigest("#{hash}#{Time.now.to_f}")

      # channel is in queuename, and we round-robin among the replay queues.
      queuename = "replays#{params[:channel]}"

      parser_id = Resque.enqueue_to(queuename, ESDB::Jobs::Sc2::Replay::PreParse, {
        :uuid => uuid,
        :hash => hash,
        :ggtracker_received_at => params[:ggtracker_received_at],
        :esdb_received_at => esdb_received_at.to_f,
        :provider_id => current_provider ? current_provider.id : nil,
        :channel => params[:channel]
      })

      success!({:job => uuid})
    end
  end
end
