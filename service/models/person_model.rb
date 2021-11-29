class Person < Hoodoo::ActiveRecord::Base
  validates :name, :presence => true
end