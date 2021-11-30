class Person < Hoodoo::ActiveRecord::Base
  # dating_enabled # Causes an issue running curl - "code": "platform.fault", "message": "PG::UndefinedTable: ERROR:  relation \"people_history_entries\" does not exist\nLINE 8:
  validates :name, :presence => true

  search_with( {
    :partial_name => Hoodoo::ActiveRecord::Finder::SearchHelper.ciaw_match_generic( :name )
  } )
end