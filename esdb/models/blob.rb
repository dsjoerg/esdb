# The Blob(TM) is a generic storage model that will store historical data for
# us, such as all unique raw request data from sc2ranks and battle.net

# attributes: 
# TODO: please, yard in this b@#§%
#
# data: Blob containing the data (likely JSON)
# created_at
# source: the source, likely a URL

class ESDB::Blob < Sequel::Model(:esdb_blobs)
end