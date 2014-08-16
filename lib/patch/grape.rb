module Grape
  class Endpoint
    # Makes the error message a hash for JSON responses
    alias_method :_error!, :error!
    def error!(message, status=403)
      message = {:error => message} if message.is_a?(String)
      message.reverse_merge!({
        :status => :error
      })
      _error!(message, status)
    end

    # In the spirit of error!, we'll have helpers with defaults for various
    # status messages. However, they will not use throw and end the request
    # These helpers should be used last in a request, as the actual response
    
    def success!(message, status=200)
      message = {:message => message} if message.is_a?(String)
      message.reverse_merge!({
        :status => :success
      }).to_json
    end
  end
end