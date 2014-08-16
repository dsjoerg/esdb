$: << File.dirname(__FILE__)

ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'bundler'
require 'sinatra/base'

Bundler.require(:default, ENV['RACK_ENV'].to_sym)

require 'yajl/json_gem'

module ESDB
  class << self
    def root
      Pathname.new(File.expand_path(File.dirname(__FILE__)))
    end

    def env
      ENV['RACK_ENV'] || 'development'
    end

    def production?
      ENV['RACK_ENV'] == 'production'
    end

    def staging?
      ENV['RACK_ENV'] == 'staging'
    end

    def log(str, severity = Logger::Severity::INFO)
      severity = "Logger::Severity::#{severity.to_s.upcase}".constantize if severity.is_a?(String) || severity.is_a?(Symbol)
      logger.add(severity) { str }
    end

    def api_key
      esdb_config['api_key']
    end

    def error(str)
      log(str, Logger::Severity::ERROR)
    end
    
    def warn(str)
      log(str, Logger::Severity::WARN)
    end

    def redis_config
      @@redis_config ||= YAML.load_file(ESDB.root.join('config/redis.yml'))[ESDB.env]
    end

    def esdb_config
      @@esdb_config ||= YAML.load_file(ESDB.root.join('config/esdb.yml'))[ESDB.env]
    end

    # Fog!
    # Seriously, why didn't I realize fog is what it is earlier. It's a 
    # "all-in-one" "cloud computing library", development sponsored by EY!
    # for S3: http://fog.io/1.6.0/storage/
    #
    # Still, some of this is pretty HAXy

    def s3cfg
      @@s3cfg ||= YAML.load(File.read('config/s3.yml'))[ESDB.env]
    end

    def fog
    end
    
    def bucket(key)
      connection = Fog::Storage.new({
        :provider                 => 'AWS',
        :aws_access_key_id        => s3cfg[key.to_s]['access_key_id'],
        :aws_secret_access_key    => s3cfg[key.to_s]['secret_access_key']
      })
      
      connection.directories.create(:key => s3cfg[key.to_s]['bucket'])
    end
  end

  # Request logging middleware, logging to both STDOUT and esdb.log for now
  # Note that there are a lot of alternatives, unicorn's own, stuff like
  # Clogger (http://clogger.rubyforge.org/) ..but I thought it'd be nice to
  # have an "example" of how to do something like this in Rack here :)
  #
  # It's being injected into the middleware stack first, in config.ru
  class RequestLogger
    attr_reader :app, :options

    def initialize(app, options = {})
      @app = app
      @options = options
    end

    def call(env)
      # puts ("-"*20) + 'DEBUG' + ("-"*20)
      # puts env.inspect
      # puts ("-"*45)

      env['gg.apilog'] = []

      _start = Time.now.to_f
      response = app.call(env)
      _time = Time.now.to_f - _start

      logstr = "Request: #{env['REQUEST_PATH']} [query:#{env['QUERY_STRING']}] (#{'%.5f' % (_time * 100)}ms) (status #{response[0]})"
      endpoint = env['api.endpoint']
      if endpoint
        logstr = "API #{logstr}, routes=#{endpoint.routes.inspect}"
      end

      puts logstr
      ESDB.log(logstr)

      # Also put out any additional stuff we acquired during the call
      # This should be used instead of ESDB.log directly where you want a
      # context - makes things easier to spot.
      env['gg.apilog'].each do |line|
        puts "\t`+ #{line}"
        ESDB.log("\t`+ #{line}")
      end

      response
    end
  end
end

# Fog ("cloud" library, AWS, etc.) configuration
# Includes CarrierWave configuration
require 'config/fog'

# Logging
require 'esdb/logging'
require 'lib/stack_logger'

if File.exists?('config/database.yml')
  dbcfg = YAML.load(File.read('config/database.yml'))
  raise "No database configuration for environment '#{ENV['RACK_ENV']}'" if !dbcfg[ENV['RACK_ENV']]

  # Force adapter to mysql2 for engineyard, which defaults to mysql, because
  # Rails will not really care what the adapter is set to and use either.
  if !['development', 'test'].include?(ESDB.env)
    dbcfg[ESDB.env]['adapter'] = 'mysql2'
  else
    if dbcfg[ESDB.env]['adapter'] != 'mysql2'
      puts "Please set your adapter in database.yml to 'mysql2'."
      exit
    end
  end

  dblogger = StackLogger.new($stdout)
  dblogger.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::WARN
  DB = Sequel.connect(dbcfg[ESDB.env], :loggers => [dblogger])
  DB.log_warn_duration = 0.05
else
  raise "You'll need a config/database.yml, matey."
end

# API
require 'esdb/api'
Dir['esdb/api/*.rb'].each {|file| require File.expand_path(file) }

# App
require 'esdb/app'

# Models
require 'esdb/model'
Dir['esdb/models/*.rb'].each {|file| require File.expand_path(file) }
Dir['esdb/models/**/*.rb'].each {|file| require File.expand_path(file) }

# Jobs
require 'esdb/job'
Dir['esdb/jobs/*.rb'].each {|file| require File.expand_path(file) }

Dir['esdb/jobs/**/*.rb'].each {|file| require File.expand_path(file) }
require 'esdb/games'

# DJ cesspool
require 'esdb/playerstats'
require 'esdb/djstat_builder'

# StatBuilder
require 'esdb/stat_builder'
require 'esdb/stat_builder/options'
require 'esdb/stat_builder/stat'
require 'esdb/stat_builder/query'
require 'esdb/stat_builder/query/sql_builder'

# Game Support
# Starcraft 2
require 'esdb/games/sc2'
Dir['esdb/games/sc2/*.rb'].each {|file| require File.expand_path(file) }

# Lib/various
Dir['lib/*.rb'].each {|file| require File.expand_path(file) }
Dir['lib/patch/*.rb'].each {|file| require File.expand_path(file) }


# Setup Redis
redis_config = YAML.load_file(ESDB.root.join('config/redis.yml'))[ESDB.env]
if redis_config
  Resque.redis = Redis.new(:host => redis_config['host'], :port => redis_config['port'])
else
  Resque.redis = Redis.new(:host => 'localhost')
end

# resque statuses should not sit in redis memory forever, yo
# see https://github.com/quirkey/resque-status
Resque::Plugins::Status::Hash.expire_in = (24 * 60 * 60) # 24hrs in seconds

# Set up caching, tell Garner to use memcached on redis_config's host, which
# should be the primary application server, or a dedicated db server/util 
# instance with both memcached and redis running for the entire app.
if ['production', 'staging'].include?(ESDB.env) || ENV['MEMCACHE']
  require 'memcached/rails'
  memcached = Memcached::Rails.new(:servers => [redis_config ? redis_config['host'] : '127.0.0.1'])

  # Test if it's running - we don't have it running on utility instances 
  # for example.

  # This will crash and burn if it can not connect to memcached and if the
  # before_symlink deploy hook let it go through without an operational 
  # memcached - we're in trouble.
  memcached.get('testing-memcached-connectivity')
  Garner.config.cache = memcached
else
  blackhole = ActiveSupport::Cache::NullStore.new()
  Garner.config.cache = blackhole
end

# If we're launched into the ripl shell, let's throw ESDB into main
if defined?(Ripl)
  include ESDB

  def reload!
    exec $0, *ARGV
  end
end
