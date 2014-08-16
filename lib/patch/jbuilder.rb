require 'lib/api_fields'

class Jbuilder
  attr_accessor :filter, :provider

  class << self
    
    # Wraps a Jbuilder.encode block inside a hash structure.
    # This is used to deliver "metadata" with our responses, such as the
    # parameters used for the request (limit, offset, page) and other 
    # accompanying information that might be required by the receiver, such
    # as the total number of objects if output limited or default values for
    # filters that could be set on a Provider level or otherwise.
    #
    # IMPORTANT: Grape is currently starting to implement "Entity" 
    # representation, which we will eventually want to use. My preliminary 
    # tests with it show it as not quite ready for primetime. We don't have the
    # time to patch/deal with problems, so we continue with jbuilder until it's
    # done. Keep an eye on https://github.com/intridea/grape
    # (It also requires some class renaming on our part, nothing major though,
    # I had it working in under an hour with no problems in my first test.)
    #
    # @param [Hash] wrapper Wrapping hash
    # @option wrapper [Integer] status Response Status (HTTP)
    # @option wrapper [Hash] params Request parameters passed back in the 
    #   response
    # @option wrapper [String] root Key for the encode block yield in the
    #   new hash structure. The collection name, for example.
    def wrap(wrapper = {}, &block)
      wrapper.symbolize_keys!
      wrapper.reverse_merge!({
        :root => :collection
      })
      
      # If params is passed straight up, we'll just clean it up here
      if wrapper[:params][:route_info]
        [:route_info, :version].each{|k| wrapper[:params].delete(k)}
      end
      
      # _yield = Jbuilder.encode(fields: wrapper[:fields], &block)
      builder = self.new
      if wrapper[:params] && wrapper[:params][:filter]
        _filter = wrapper[:params][:filter]
        _filter = ApiFields::Parser.parse(_filter) if _filter.is_a?(String)
        builder.filter = _filter
      end
      
      builder.provider = wrapper[:provider] if wrapper[:provider]

      yield builder

      wrapper[wrapper.delete(:root)] = builder.attributes!
      wrapper.to_json
    end
  end

  # Inject our ApiFields opject, if present in params.
  # This allows us to call builder.fields anywhere in the chain
  # api.rb defaults params[:fields], but we'll make sure there is something
  # here as well.
  def filter
    @filter || ::ApiFields::Blank.new
  end
end