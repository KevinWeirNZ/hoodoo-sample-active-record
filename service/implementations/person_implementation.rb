class PersonImplementation < Hoodoo::Services::Implementation

  def show( context )
    person = Person.acquire_in( context )
    if person.nil?
      context.response.not_found( context.request.ident )
    else
      context.response.set_resource( render_in( context, person ) )
    end
  end

  # TODO in list:
  # tidy up and refactor
  def list( context )
    context.request.list.limit= 1000 if context.request.list.limit > 1000 # Limit the size of page size a caller can request.
    finder = Person.list_in( context )

    # year
    date_of_birth_year        = context.request.list.search_data[ 'date_of_birth_year'         ].to_i
    date_of_birth_year_after  = context.request.list.search_data[ 'date_of_birth_year_after'   ].to_i
    date_of_birth_year_before = context.request.list.search_data[ 'date_of_birth_year_before'  ].to_i

    # date of birth
    date_of_birth             = context.request.list.search_data[ 'date_of_birth'              ].to_s
    date_of_birth_after       = context.request.list.search_data[ 'date_of_birth_after'        ].to_s
    date_of_birth_before      = context.request.list.search_data[ 'date_of_birth_before'       ].to_s

    #minimum and maximum dates for postgres
    minimum_date = Date.parse( '4713-01-01 BCE' )
    maximum_date = Date.parse( '294276-01-01'   )

    # If no values have been provided for any of the 'date of birth variables'
    if date_of_birth.empty? & date_of_birth_before.empty? & date_of_birth_after.empty?
      # search for an exact date of birth year
      if date_of_birth_year_before.zero? & date_of_birth_year_after.zero? & !date_of_birth_year.zero?
        finder = finder.where( :date_of_birth => ( Date.new( date_of_birth_year ) ... Date.new( date_of_birth_year + 1 ) ) )
      # Search for all entries before date of birth year.
      elsif date_of_birth_year.zero? & date_of_birth_year_after.zero? & !date_of_birth_year_before.zero?
        finder = finder.where( :date_of_birth => ( minimum_date ... Date.new( date_of_birth_year_before ) ) )
      # Search for all entries after date of birth year
      elsif date_of_birth_year.zero? & date_of_birth_year_before.zero? & !date_of_birth_year_after.zero?
        finder = finder.where( :date_of_birth => ( Date.new( date_of_birth_year_after + 1 ) ... maximum_date ) )
      # Search for all entries between two given dates - date_of_birth_year_before and date_of_birth_year_after.
      elsif date_of_birth_year.zero? & !date_of_birth_year_before.zero? & !date_of_birth_year_after.zero?
        finder = finder.where( :date_of_birth => ( Date.new( date_of_birth_year_after - 1 ) ... Date.new(date_of_birth_year_before + 1 ) ) )
      end

    # If no values have been provided for any of the 'date of birth year variables'
    elsif date_of_birth_year.zero? & date_of_birth_year_before.zero? & date_of_birth_year_after.zero?
      # Search for all entries that exactly equal the given date of birth.
      if date_of_birth_before.empty? & date_of_birth_after.empty? & !date_of_birth.empty?
        date_of_birth   = Date.parse( date_of_birth )
        finder = finder.where( :date_of_birth => ( date_of_birth ... ( date_of_birth + 1.days   ) ) )
      # Search for all entries before date of birth.
      elsif date_of_birth.empty? & date_of_birth_after.empty? & !date_of_birth_before.empty?
        finder = finder.where( :date_of_birth => ( minimum_date ... Date.parse( date_of_birth_before ) ) )
      # Search for all entries after date of birth.
      elsif date_of_birth.empty? & date_of_birth_before.empty? & !date_of_birth_after.empty?
        finder = finder.where( :date_of_birth => ( Date.parse( date_of_birth_after ) ... maximum_date ) )
      # Search for all entries between two given dates - date_of_birth_before and date_of_birth_after.
      elsif date_of_birth.empty? & !date_of_birth_before.empty? & !date_of_birth_after.empty?
        date_of_birth_before   = Date.parse( date_of_birth_before )
        date_of_birth_after    = Date.parse( date_of_birth_after  )
        finder = finder.where( :date_of_birth => ( ( date_of_birth_after - 1 ) ... ( date_of_birth_before + 1 ) ) )
      end
    end
    byebug
      list = finder.all.map { | person | render_in( context, person ) }
      context.response.set_resources( list, finder.dataset_size )
  end

  def create( context )
    person = Person.new_in( context, context.request.body )
    unless person.persist_in( context ) === :success
      context.response.add_errors( person.platform_errors )
      return
    end
    context.response.set_resources( render_in( context, person ) )
  end

  def update( context )
    person = Person.acquire_in( context )

    if person.nil?
      context.response.not_found( context.request.ident )
      return
    end
    person.assign_attributes( context.request.body )
    unless person.persist_in( context ) === :success
      context.response.add_errors( person.platform_errors )
      return
    end
    context.response.set_resources( render_in( context, person.reload ) )
  end

  def delete( context )
    person = Person.acquire_in( context )
    if person.nil?
      context.response.not_found( context.request.ident )
      return
    end
    rendered = render_in( context, person )
    person.delete()
    context.response.set_resources( rendered )
  end

  private
  # This avoids code duplication between the action methods,
  # concentrating the call to Hoodoo's presenter layer and
  # the database-to-resource mapping into one place.
  #
  def render_in( context, person )
    resource_fields = {
      'name' => person.name
    }

    if person.date_of_birth.present?
      resource_fields[ 'date_of_birth' ] = person.date_of_birth.iso8601()
    end

    options = {
      :uuid       => person.id,
      :created_at => person.created_at
    }

    Resources::Person.render_in(
      context,
      resource_fields,
      options
    )
  end
end
