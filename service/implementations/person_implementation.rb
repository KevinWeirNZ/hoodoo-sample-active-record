class PersonImplementation < Hoodoo::Services::Implementation

  def show( context )
    person = Person.acquire_in( context )
    if person.nil?
      context.response.not_found( context.request.ident )
    else
      context.response.set_resource( render_in( context, person ) )
    end
  end


  def list( context )
    context.request.list.limit= 1000 if context.request.list.limit > 1000 # Limit the size of page size a caller can request.

    # Parse and validate the date search parameters
    # Date of birth
    dob        = validate_date_field( context, 'date_of_birth'        )
    dob_after  = validate_date_field( context, 'date_of_birth_after'  )
    dob_before = validate_date_field( context, 'date_of_birth_before' )
    validate_date_range( context, dob_after, dob_before )

    # Year only
    dob_year        = validate_date_year_field( context, 'date_of_birth_year'        )
    dob_year_after  = validate_date_year_field( context, 'date_of_birth_year_after'  )
    dob_year_before = validate_date_year_field( context, 'date_of_birth_year_before' )
    validate_date_range( context, dob_year_after, dob_year_before )
    return if context.response.halt_processing?

    # Find the right data
    finder = Person.list_in( context )

    list   = finder.all.map { | person | render_in( context, person ) }
    # Date of birth
    finder = where_dob_exactly( finder, dob )
    finder = where_dob_before( finder, dob_before )
    finder = where_dob_after( finder, dob_after )
    # Year Only
    finder = where_dob_year_exactly( finder, dob_year )
    finder = where_dob_year_before( finder, dob_year_before )
    finder = where_dob_year_after( finder, dob_year_after )

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

  def validate_date_field(context, key)
    date = nil
    if context.request.list.search_data.has_key?(key)
      # Get the value of the key and parse as an iso8601 date. This will strip any time value from the timestamp
      # before Hoodoo::Utilities validates that the 'key' date is in  the correct format.
      key = context.request.list.search_data[ key ]
      key = Date.parse( key ).iso8601()
      date = Hoodoo::Utilities.valid_iso8601_subset_date?( key )
      if date == false
        context.response.add_error(
          "generic.invalid_parameters",
          message: "Invalid date",
          reference: { field_names: "date_of_birth" }
        )
      end
    end
    return date
  end

  def validate_date_year_field(context, key)
    date = nil
    if context.request.list.search_data.has_key?(key)
      key = context.request.list.search_data[ key ].to_i          # Converting the value to an integer will strip out any data after the hyphen i.e.(2000-01-01) will equal 2000
      key = Date.new( key ).iso8601()                             # Convert to iso8601 format.
      date = Hoodoo::Utilities.valid_iso8601_subset_date?( key )  # Validate that the date is iso8601 before returning the date.
      if date == false
        context.response.add_error(
          "generic.invalid_parameters",
          message: "Invalid date",
          reference: { field_names: "date_of_birth" }
        )
      end
    end
    return date
  end

  def validate_date_range(context, date1, date2)
    return if date1.nil? || date2.nil?
      if date2 < date1
        context.response.add_error(
          'generic.invalid_parameters',
          message: 'invalid date range date_of_birth_after should not be larger than date_of_birth_before',
          reference:{ field_names: 'date_of_birth'}
        )
      end
  end

  # Date of birth
  def where_dob_exactly( finder, date )
    return finder if date.nil?
    finder.where( 'date_of_birth::TIMESTAMP::DATE = ?::TIMESTAMP::DATE', date)
  end

  def where_dob_before( finder, date )
    return finder if date.nil?
    finder.where( 'date_of_birth::TIMESTAMP::DATE <= ?::TIMESTAMP::DATE', date)
  end

  def where_dob_after( finder, date )
    return finder if date.nil?
    finder.where( 'date_of_birth::TIMESTAMP::DATE >= ?::TIMESTAMP::DATE', date)
  end

  # Year only
  def where_dob_year_exactly( finder, date )
    return finder if date.nil?
    year = (date).strftime("%Y")  # Extract year from the date passed into the method
    finder.where( 'EXTRACT(YEAR FROM date_of_birth::TIMESTAMP::DATE) = ?', year)
  end

  def where_dob_year_before( finder, date )
    return finder if date.nil?
    year = (date).strftime("%Y")  # Extract year from the date passed into the method
    finder.where( 'EXTRACT(YEAR FROM date_of_birth::TIMESTAMP::DATE) <= ?', year)
  end

  def where_dob_year_after( finder, date )
    return finder if date.nil?
    year = (date).strftime("%Y")  # Extract year from the date passed into the method
    finder.where( 'EXTRACT(YEAR FROM date_of_birth::TIMESTAMP::DATE) >= ?', year)
  end
end
