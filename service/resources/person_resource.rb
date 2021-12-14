module Resources
  class Person < Hoodoo::Presenters::Base
    schema do
      string :name, :required => true, :length => 256
      date   :date_of_birth
    end
  end
end