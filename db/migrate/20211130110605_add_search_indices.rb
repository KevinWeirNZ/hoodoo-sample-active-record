class AddSearchIndices < ActiveRecord::Migration[5.1]
  def up
    add_index :people, :name
    add_index :people, :date_of_birth
  end

  def down
    drop_index :people, :name
    drop_index :people, :date_of_birth
  end
end
