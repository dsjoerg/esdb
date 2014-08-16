# Patch Memcached::Rails 
# https://github.com/evan/memcached/blob/master/lib/memcached/rails.rb
# To attempt to reconnect and ignore Memcached::ServerIsMarkedDead
#
# Note: we really don't care if the "reconnect" worked, we'll just continue
# to ignore the cache until it comes back.

require 'memcached/rails'

class Memcached
  class Rails
    # Something is happening here with threads not attempting to re-connect to
    # memcached correctly, or lingering dead connections.
    # TODO: may want to investigate rather than use this blunt approach.
    def reconnect!
      server = ESDB.redis_config ? ESDB.redis_config['host'] : '127.0.0.1'
      ESDB.log("attempting to re-establish memcached connection to #{server}")
      memcached = Memcached::Rails.new(:servers => [server])
      Garner.config.cache = memcached
    end

    alias_method :_get, :get
    def get(*args)
      _get(*args)
    rescue Memcached::ServerIsMarkedDead
      ESDB.log('memcached has gone away')
      reconnect!
      nil
    end

    alias_method :_set, :set
    def set(*args)
      _set(*args)
    rescue Memcached::ServerIsMarkedDead
      ESDB.log('memcached has gone away')
      reconnect!
      nil
    end
  end
end