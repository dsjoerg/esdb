# Providers are one of the ways to identify the source of a replay.
#
# We might have a drop.sc Provider for replays that we receive from their site
# and will have providers for various tournaments, such as MLG.
#
# Eventually, we might even make this a tree, with different tournament types
# such as MLG's Arena and Championship formats parented to the "MLG" provider
# in order to be able to pull statistics for just their arena, or just their
# championship events.
#
# *Important Attributes*
#
# callback_url
#
# URL to which all callbacks are sent. Documentation to follow.
# In a nutshell: processes that require rapid notification/communication
# will send calls to this URL to discourage the repeated polling of the API
#
# e.g.: Replay processing will send calls on every progress update so the
# ggtracker frontend does not need to poll the API for it repeatedly.
#
# Eventually, this moves into the database and is definable by a Provider but
# for now it's only used in development and thusly.. TODO

class ESDB::Provider < Sequel::Model(:esdb_providers)

  one_to_many :identities, :class => 'ESDB::Provider::Identity'

  def validate
    super
    errors.add(:callback_url, 'is not a valid URL') unless !callback_url || callback_url =~ /\Ahttps?:\/\//
  end
  
  # Calls the callback_url with given call and data (params)
  def callback(call, data)
    Curl.get(callback_url, {:call => call}.merge(data)) if callback_url
  end

  # Is the provider ggtracker?
  # TODO: lose match by name, likely not a good idea.
  def ggtracker?
    name.downcase == 'ggtracker' ? true : false
  end
  
  def self.ggt_provider
    if @ggt_provider.nil?
      @ggt_provider = Provider.where(:name => 'ggtracker').first
    end

    @ggt_provider
  end
end
