FactoryGirl.define do
  # TODO: I don't like this - should try to get FG to let us use the fully
  # namespaced class name as factory name somehow.
  #
  # But.. this isn't too bad. So consider carefully.
  # (Think multiple aliases for the same class with different defaults)
  factory :sc2_identity, :class => ESDB::Sc2::Identity do
    name{Faker::Name.first_name}
    bnet_id{rand(99999)}
    subregion(1)
    gateway('eu')
  end
end
