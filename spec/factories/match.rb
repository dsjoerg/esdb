FactoryGirl.define do
  factory :match, :class => ESDB::Match do
    played_at{Time.at(Time.now.to_f-(rand(86400*7)))}
    duration_seconds{300}

    after(:create) do |match, evaluator|
      FactoryGirl.create_list(:sc2_match_entity, 2, match: match)
    end
  end
  
  factory :sc2_match_entity, :class => ESDB::Sc2::Match::Entity do
    apm{rand(150)}
    wpm{rand(4.0)}

    after(:create) do |entity, evaluator|
      identity = FactoryGirl.create(:sc2_identity)
      entity.add_identity(identity)
      entity.save
    end
  end
end
