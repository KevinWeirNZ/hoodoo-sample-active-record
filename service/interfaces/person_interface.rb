class PersonInterface < Hoodoo::Services::Interface
  interface :Person do
    endpoint :people, PersonImplementation
    public_actions :show,
                   :list,
                   :create,
                   :update,
                   :delete

    to_create do
      resource Resources::Person
    end

    update_same_as_create

    to_list do
      sort default( :date_of_birth) => [ :asc, :desc ],
           :name                    => [ :asc, :desc ]
      search :partial_name,
             :date_of_birth_year,
             :date_of_birth_year_before,
             :date_of_birth_year_after,
             :date_of_birth,
             :date_of_birth_before,
             :date_of_birth_after

    end
  end
end
