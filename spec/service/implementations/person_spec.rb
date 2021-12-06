require 'spec_helper'

RSpec.describe PersonImplementation do

  #Test that the schema is working as intended.
  #these two tests will add and delete a person into the database.


  it 'adds a row from the person table, on create' do
    post "/1/Person",
    { name: 'John' }.to_json,
    { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    expect(last_response.status).to eq 200

  end

  let(:person){FactoryBot.create(:person)} # mock an instance of a person for testing

  it "returns 200 if successful" do
    delete "/1/Person/#{person.id}",
    nil,
    { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    expect(last_response.status).to eq 200
  end
end
