class ESDB::Match_Deleted < Sequel::Model(:esdb_matches_deleted)
  many_to_one :match, :class => 'ESDB::Match'
end
