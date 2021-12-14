require 'spec_helper'

RSpec.describe PersonImplementation do

  #Test that the schema is working as intended.
  #these two tests will add and delete a person into the database.
  it 'adds a row from the person table' do
    expect { post "/1/Person", { name: 'John' }.to_json, 'CONTENT_TYPE' => 'application/json; charset=utf-8' }.to change(Person, :count).by(1)
  end

  it 'deletes a row from the person table' do
    person = FactoryBot.create(:person_with_dob)
    expect { delete "/1/Person/#{person.id}", nil, 'CONTENT_TYPE' => 'application/json; charset=utf-8' }.to change(Person, :count).by(-1)
  end
end
