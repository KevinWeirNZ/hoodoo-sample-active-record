class CreatePeople < ActiveRecord::Migration[5.1]
  def self.up

    # Note important use of ":id => :string" to define a
    # non-numeric primary key that can accept a UUID.
    #
    create_table :people, :id => :string do | t |
      t.string :name, :null => false
      t.date   :date_of_birth

      t.timestamps :null => false
    end

    # Limit the primary key to the maximum UUID length of 32
    # characters, to help the database work more efficiently.
    #
    change_column :people, :id, :string, :limit => 32

  end

  def self.down
    drop_table :people
  end
end
