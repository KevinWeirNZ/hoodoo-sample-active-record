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
    finder = Person.list_in( context )
    birth_year = context.request.list.search_data['birth_year'].to_i
    before_date = context.request.list.search_data['before_date'].to_i
    after_date = context.request.list.search_data['after_date'].to_i

    if before_date.zero? & after_date.zero?
      unless birth_year.zero?
        this_year_start = Date.new( birth_year )
        next_year_start = Date.new(birth_year + 1 )
        finder = finder.where( :date_of_birth => (this_year_start ... next_year_start))
      end
    elsif
      # This is the functionality for searching all records with a birth year after a given year.
      unless after_date.zero?
        long_after_date = Date.new( birth_year + 1000 )
        after_date = Date.new( birth_year + 1 )
        finder = finder.where( :date_of_birth => (after_date ... long_after_date))
      end
    else
      # This is the functionality for searching all records with a birth year before a given year.
      unless before_date.zero?
        years_ago = Date.new(birth_year - 150)
        before_date = Date.new( birth_year )
        finder = finder.where( :date_of_birth => (years_ago ... before_date))
      end
    end

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
