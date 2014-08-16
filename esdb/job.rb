# Superclass for all Resque jobs, provides proper logger, etc.

module ESDB
  class Job
    include ESDB::Logging

    # We don't want all the args in the name..
    def name
      self.class.to_s
    end

    # Overwriting both Logging and Status #logger here to provide job details
    def logger
      @logger ||= ESDB.logger.dup
      @logger.progname = "#{self.class.to_s}(#{uuid})"
      @logger
    end

    # Notify humans if the queue sizes explode
    def self.after_enqueue_notify_humans(*args)
      if ['production', 'staging'].include?(ESDB.env)
        # Order is important, only the first match will trigger an alert!
        thresholds = {
          "scraping-crit" => {
            apocalypse: 4,
            critical: 3,
            warning: 2
          },
          "scraping" => {
            apocalypse: 5000,
            critical: 1000,
            warning: 300
          },
          "python-low" => {
            apocalypse: 999999,
            critical: 999999,
            warning: 999999
          },
          "default" => {
            apocalypse: 5000,
            critical: 1000,
            warning: 200
          }
        }

        alerted = []

        Resque.queues.each do |q|
          thresh = thresholds[q]
          thresh ||= thresholds["default"]
          thresh.each do |k, s|
            ss = Resque.size(q)
            if ss > s
              if !alerted.include?(q)
                ESDB.log("Queue #{q} is #{k}: #{ss} (>#{s})")
              end
              alerted << q
            end
          end
        end

      end
    end

    private

    def set_status(*args)
      old_status = self.status
      self.status = [status, {'name'  => self.name}, args].flatten

      logger.info("#{self.status.status}: #{self.status.message} (#{self.status.pct_complete}%)") if old_status != self.status
    end
  end
end
