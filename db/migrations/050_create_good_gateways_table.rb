Sequel.migration do
  change do
    create_table(:esdb_good_gateways) do
      String :gateway
    end
    run 'insert into esdb_good_gateways (gateway) values ("us")'
    run 'insert into esdb_good_gateways (gateway) values ("eu")'
    run 'insert into esdb_good_gateways (gateway) values ("sea")'
    run 'insert into esdb_good_gateways (gateway) values ("kr")'
  end
end
