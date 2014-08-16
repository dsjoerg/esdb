# This is not a model in itself, it's the superclass for all game-specific
# identity models. Shared functions are defined here and should/can be
# overridden in those models.
#

class ESDB::Identity < Sequel::Model(:esdb_identities)

  plugin :many_through_many
  plugin :single_table_inheritance, :type

  one_to_many :identity_entities
  many_to_many :entities, :join_table => :esdb_identity_entities, :class => 'ESDB::Sc2::Match::Entity'
  many_through_many :matches, [[:esdb_identity_entities, :identity_id, :entity_id], [:esdb_sc2_match_entities, :id, :match_id]], :class => 'ESDB::Match'

  many_to_many :left_identities, :left_key => :left_id, 
    :right_key => :right_id,
    :join_table => :esdb_identity_identities, :class => self

  many_to_many :right_identities, :left_key => :right_id, 
    :right_key => :left_id,
    :join_table => :esdb_identity_identities, :class => self

  # Returns the combined left and right identities.
  def identities(where = nil)
    if where
      left_identities.where(where).all + right_identities.where(where).all
    else
      left_identities + right_identities
    end
  end
  
  def add_identity(identity)
    add_left_identity(identity)
  end

  # Returns the first provider identity belonging to this Identity for the
  # given provider (or self, if we're a Provider::Identity for that provider)
  def provider_identity_for(_provider)
    return self if self.type == 'ESDB::Provider::Identity' && self.provider_id == _provider.id
    pids = identities.reject{|i| i.type != 'ESDB::Provider::Identity' || i.provider_id != _provider.id}
    pids.first
  end

  # Cache Invalidation
  # called after save and at the end of postparse! and postscrape!
  def invalidate_cache!
    Garner::Cache::ObjectIdentity.invalidate(ESDB::Identity, self.id)
    Garner::Cache::ObjectIdentity.invalidate(ESDB::Identity)
    Garner::Cache::ObjectIdentity.invalidate(ESDB::Match)

    # Also invalidate for all matches
    matches_dataset.select(:id).qualify.each do |match|
      Garner::Cache::ObjectIdentity.invalidate(ESDB::Match, match.id)
    end
  end

  def after_save
    invalidate_cache!
  end

  # Builds an Identity from the given URL (battle.net)
  def self.from_url(url)
    bs = BnetScraper::Starcraft2::ProfileScraper.new(:url => url)
    puts "no bs!" if !bs
    return nil if !bs

    identity = self.new({
      :name         => bs.name,
      :gateway      => bs.gateway,
      :bnet_id      => bs.bnet_id,
      :subregion    => bs.subregion
    })

    return identity
  end

  # Finds an identity for the given URL (battle.net)
  def self.for_url(url)
    bs = BnetScraper::Starcraft2::ProfileScraper.new(:url => url)
    return nil if !bs

    # note that name is not in the search criteria. this is
    # intentional and good.  gateway, subregion and bnet_id alone
    # uniquely identify a battle.net account, and this way we'll find
    # the identity in our DB even if the name is not what we expected
    # from the supplied URL.
    identity = self.where({
      :gateway      => bs.gateway,
      :subregion    => bs.subregion,
      :bnet_id      => bs.bnet_id
    }).first

    return identity
  end

  # Returns all providers that this identity is attached to
  def providers
    pids = identities.reject{|i| i.type != 'ESDB::Provider::Identity'}
    pids.collect(&:provider)
  end

  # Is this identity the account of a ggtracker user?
  def ggtracker_linked?
    identities.count > 0
  end


  # Has this identity enough information to receive battle.net profile
  # information (even just via sc2ranks)?
  #
  # Used to establish the type in api/identities for example.
  def bnet_identifiable?
    # Does it have a profile url?
    return true if !profile_url.blank?
    # Or what we need to construct a profile url?
    # (Note that name is formally required by sc2ranks, but is ignored!
    # So having a name is not really required, we'll simply give "Unknown" if we dont know it.)
    return true if bnet_id && subregion && gateway
    false
  end

  def self.random
    self.order(Sequel.function(:RAND)).first
  end

  # Overwrite in models that inherit from ESDB::Identity
  def enqueue!
    ESDB.logger.error("ESDB::Identity#enqueue! was called from #{caller[0]}")
  end
  
  def to_hash
    # Simply default all current attributes in here for now
    data = values
    data[:type] = data[:type].to_s
    
    data
  end

  # Serialize to Jbuilder
  def to_builder(options = {})
    builder = options[:builder] || jbuilder(options)
    builder.(self, :id, :type, :name, :provider_id, :provider_ident)
    builder
  end
end
