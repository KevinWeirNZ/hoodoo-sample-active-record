FactoryBot.define do
  factory :person do
    name { Faker::Name.name }

    factory :person_with_dob do
      date_of_birth { Faker::Date.between( 80.years.ago, 10.years.ago ) }
    end
  end
end