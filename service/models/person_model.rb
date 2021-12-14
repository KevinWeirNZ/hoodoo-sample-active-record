class Person < Hoodoo::ActiveRecord::Base
  validates :name, :presence => true

  search_with( {
    :partial_name => Hoodoo::ActiveRecord::Finder::SearchHelper.ciaw_match_generic( :name )
  } )
end