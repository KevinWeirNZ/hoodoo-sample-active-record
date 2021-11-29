class PersonImplementation < Hoodoo::Services::Implementation

  def show( context )
    person = Person.acquire_in!( context )
    return if context.response.halt_processing?
    context.response.set_resources( render_in( context, person ) )
  end

  def list( context )
    context.request.list.limitv= 1000 if context.request.list.limit > 1000 # Limit the size of page size a caller can request.
    finder = Person.list_in( context )
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
