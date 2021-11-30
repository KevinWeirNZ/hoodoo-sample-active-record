class AddIndexToName < ActiveRecord::Migration[5.1]
  def up
    # add_index :people, :name
  end

  def down
    # drop_index :people, :name
  end
end
