require 'spec_helper'
require 'json'

RSpec.describe 'Person integration' do

  context '#create' do

    it 'returns 200' do
      post "/1/Person",
      { "name": 'John' }.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq 200
    end

    it 'returns the valid response when post a persons name' do
      post "/1/Person",
      { "name": "John" }.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      message = %({ "name":"John","kind":"Person" })
      expect(last_response.body).to be_json_eql(message)
    end

    it 'returns the valid response when post a persons name and DOB' do
      post "/1/Person",
      { "name": "John" , "date_of_birth": "1996-01-01"}.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      message = %({ "name":"John","date_of_birth":"1996-01-01","kind":"Person" })
      expect(last_response.body).to be_json_eql(message)
    end

    it "returns 422 when payload is in the wrong format" do
      post "/1/Person",
      { "name": "John" , "birthday": "1996-01-01"}.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(422)
    end

    it "renders incorrectly when date of birth type is incorrect." do
      post "/1/Person",
      { "name": "John" , "birthday": "1996-01-01"}.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      message = %({
        "errors": [
          {
            "code": "generic.invalid_parameters",
            "message": "Body data contains unrecognised or prohibited fields",
            "reference": "birthday"
          }
        ],
        "kind": "Errors"})
      expect(last_response.body).to be_json_eql(message).excluding("interaction_id")
    end

    it "renders incorrectly when date of birth is missing." do
      post "/1/Person",
      { "name": "John" , "date_of_birth": ""}.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      message = %({
        "errors": [
          {
            "code": "generic.invalid_date",
            "message": "Field `date_of_birth` is an invalid ISO8601 date",
            "reference": "date_of_birth"
          }
        ],
        "kind": "Errors"})
      expect(last_response.body).to be_json_eql(message).excluding("interaction_id")
    end

    it "renders incorrectly when an addition field is present." do
      post "/1/Person",
      { "name": "John" , "date_of_birth": "1999-01-01", "has_been_to_the_zoo": "yes"}.to_json,
      { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      message = %({
        "errors": [
          {
            "code": "generic.invalid_parameters",
            "message": "Body data contains unrecognised or prohibited fields",
            "reference": "has_been_to_the_zoo"
          }
        ],
        "kind": "Errors"})
      expect(last_response.body).to be_json_eql(message).excluding("interaction_id")
    end



  end

  context "#update" do

    context "Person exists" do
      let(:person){FactoryBot.create(:person)} # mock an instance of a person for testing

      it "successful update http 200" do
        # Add the mock person ID to the query
        patch "/1/Person/#{person.id}",
        {"name": "John"}.to_json,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq 200
      end

      it "updates the mock persons name" do
        # Add the mock person ID to the query
        patch "/1/Person/#{person.id}",
        {"name": "John", "date_of_birth": "1996-01-01"}.to_json,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        message =%({"name": "John" , "date_of_birth": "1996-01-01" , "kind": "Person"})
        expect(last_response.body).to be_json_eql(message)
      end

      it "returns 422 when date of birth is invalid" do
        # Add the mock person ID to the query
        patch "/1/Person/#{person.id}",
        {"name": "John", "birthday": "today"}.to_json,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq 422
      end
    end

    context "Person doesn't exist" do
      let(:person){FactoryBot.create(:person)} # mock an instance of a person for testing
      let(:id) { Hoodoo::UUID.generate}# generate a random UUID to mock an id that is not in the db.

      it "returns 404 when updating an invalid id" do
        patch "/1/Person/#{id}",
        {"name": "John"}.to_json,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq 404
      end

      it "returns the correct error message when attempting to update an invalid id" do
        patch "/1/Person/#{id}",
        {"name": "John"}.to_json,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        message = %({
          "errors": [
            {
              "code": "generic.not_found",
              "message": "Resource not found",
              "reference": "#{id}"
            }
          ],
          "kind": "Errors"})
        expect(last_response.body).to be_json_eql(message).excluding("interaction_id")
      end

      it "returns the correct error message when attempting to update an invalid id" do
        patch "/1/Person/#{person.id}",
        {"name": "John", "number_of_cats": "12"}.to_json,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        message = %({
          "errors": [
            {
              "code": "generic.invalid_parameters",
              "message": "Body data contains unrecognised or prohibited fields",
              "reference": "number_of_cats"
            }
          ],
          "kind": "Errors"})
        expect(last_response.body).to be_json_eql(message).excluding("interaction_id")
      end
    end
  end


  context "#delete" do

    context "Person exists" do

      let(:person){FactoryBot.create(:person)} # mock an instance of a person for testing

      it "returns 200 if successful" do
        delete "/1/Person/#{person.id}",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq 200
      end

      it "deletes a person correctly" do
        delete "/1/Person/#{person.id}",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        message = %({"name": "#{person.name}","kind": "Person"})
        expect(last_response.body).to be_json_eql(message)
      end

    end

    context "Person doesn't exist" do
      let(:id) { Hoodoo::UUID.generate}# generate a random UUID to mock an id that is not in the db.

      it "returns 404 if unsucessful" do
        delete "/1/Person/#{id}",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq 404
      end

      it "deletes a person correctly" do
        delete "/1/Person/#{id}",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        msg = %(
          {
            "errors": [
              {
                "code": "generic.not_found",
                "message": "Resource not found",
                "reference": "#{id}"
              }
            ],
            "kind": "Errors"
          }
        )
        expect(last_response.body).to be_json_eql(msg).excluding("interaction_id")
      end
    end
  end

  context "#list" do

    context "database contains multiple people" do
      let(:a){FactoryBot.create(:person)}
      let(:b){FactoryBot.create(:person)}
      let(:c){FactoryBot.create(:person)}

      it "returns 200" do
        get "/1/Person/",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq 200
      end

      it "returns the correct message" do
        get "/1/Person/",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        message =%({"name": "#{a.name}", "name": "#{b.name}", "name": "#{c.name}", "kind": "Person"})
      end
    end

  end

  context "#show" do

    context "Person exists" do
      let(:person){FactoryBot.create(:person)}

      it "returns 200" do
        get "/1/Person/#{person.id}",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq 200
      end

      it"returns the correct message when successful" do
        get "/1/Person/#{person.id}",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        message =%({"name": "#{person.name}", "kind": "Person"})
        expect(last_response.body).to be_json_eql(message)
      end
    end

    context "Person doesn't exist" do
      let(:id) { Hoodoo::UUID.generate}

      it "returns 404" do
        get "/1/Person/#{id}",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect(last_response.status).to eq 404
      end
    end
  end

  context "#search" do
     before :each do
      @p1 = FactoryBot.create( :person, :name => 'John 1', :date_of_birth => '2002-03-01' )
      @p2 = FactoryBot.create( :person, :name => 'John 2', :date_of_birth => '2002-09-04' )
      @p3 = FactoryBot.create( :person, :name => 'Dylan 1',   :date_of_birth => '2000-11-23' )
      @p4 = FactoryBot.create( :person, :name => 'Dylan 2',   :date_of_birth => '1996-02-01' )
     end

    def do_list( search = {}, expected_code = 200 )
      query = ''
      unless search.empty?
        encoded_search = URI.encode_www_form( search )
        query = '?' << URI.encode_www_form( 'search' => encoded_search )
      end
      response = get(
        "/1/Person#{ query }",
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )
      expect( last_response.status).to(
        eq( expected_code )
      )
      return JSON.parse( response.body )
    end


  def compare_lists( resources, *models )
    models.each_with_index do | model, index |
      resource = resources[ '_data' ][ index ]
      expect( model.name                  ).to eq( resource[ 'name'          ] )
      expect( model.date_of_birth.iso8601 ).to eq( resource[ 'date_of_birth' ] )
    end
  end

  def compare_lists_after( resources, *models )
    models.each_with_index do | model, index |
      resource = resources[ '_data' ][ index ]
      expect( model.name                  ).to eq( resource[ 'name'          ] )
      expect( model.date_of_birth.iso8601 ).to eq( resource[ 'date_of_birth' ] )
    end
  end

      it "searches for those born in 2000" do
        res = do_list( :birth_year => '2000')
        compare_lists(res, @p3)
      end

      it "searches for those born before 2000" do
        res = do_list( :birth_year => '2000', :before_date => '1')
        compare_lists(res, @p4)
      end

      it "searches for those born after 2000" do
        res = do_list( :birth_year => '2000', :after_date => '1')
        compare_lists_after(res, @p2, @p1)
      end

  end

end
