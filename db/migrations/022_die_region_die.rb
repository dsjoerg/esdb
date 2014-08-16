region_to_gateway = {"eu" => "eu",
                     "kr" => "kr",
                     "la" => "us",
                     "na" => "us",
                     "ru" => "eu"}

realm_to_gateway = {"eu" => "eu",
                    "na" => "us"}

Sequel.migration do
  up do
    self[:esdb_identities].all do |r|
      r.update(:subregion=>region_to_gateway[r[:region]])
    end
    self[:esdb_sc2_match_summaries].all do |r|
      r.update(:realm=>realm_to_gateway[r[:realm]])
    end
    alter_table(:esdb_identities) do
      drop_column :region
      add_index [:bnet_id, :subregion, :gateway], :unique=>true
    end
    alter_table(:esdb_sc2_match_summaries) do
      rename_column :realm, :gateway
    end
  end
end
