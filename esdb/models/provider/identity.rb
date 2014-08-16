class ESDB::Provider::Identity < ESDB::Identity
  
  many_to_one :provider, :class => 'ESDB::Provider'
end
