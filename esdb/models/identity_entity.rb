# I would prefer to do this without a model for the join table, but for now..

class ESDB::IdentityEntity < Sequel::Model(:esdb_identity_entities)

  set_primary_key [:identity_id, :entity_id]

end