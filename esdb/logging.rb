# I had to go the lazy mans approach here to not waste too much time, but I'd
# much rather go the fancy way, which is why there's a commented out second
# approach.
#
# However - this provides a logger object for classes that include it which
# will default its progname to the class that included it. Makes logs look
# nicer.
#
# Where not wanted or needed, one can simply call it from the main ESDB module
# via ESDB.logger

module ESDB
  module Logging
    def self.included(base)
      class << base; attr_accessor :logger; end
      FileUtils.mkdir_p(ESDB.root.join('log'))

      log_file = File.open(ESDB.root.join('log', 'esdb.log'), File::WRONLY | File::APPEND | File::CREAT)
      log_file.sync = true

      base.logger = Logger.new(log_file)
      base.logger.progname = base.to_s
      base.logger.level = ENV['DEBUG'] ? Logger::Severity::DEBUG : Logger::Severity::INFO
    end

    # Also fall back to ESDB.logger which should always be available
    def logger
      self.class.logger || ESDB.logger
    end

    # class Logger < ::Logger
    #   ['info', 'warn', 'error', 'fatal', 'debug'].each do |call|
    #     define_method(call) do |message, &block|
    #       super(message, &block) and return if block
    #       super(@progname) { message }
    #     end
    #   end
    # end
    # 
    # @@logger = nil
    # 
    # def logger
    #   if !@@logger
    #     @@logger = Logger.new(STDOUT)
    # 
    #     # TODO: set up nicer formatting?
    #   end
    #   
    #   @@logger
    # end
  end
end

# Include it in the ESDB root module so we can call ESDB.logger
ESDB.send(:include, ESDB::Logging)

# And
Grape::API.send(:include, ESDB::Logging)
