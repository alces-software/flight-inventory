class CreateNetworks < ActiveRecord::Migration[5.2]
  def change
    create_table :networks do |t|
      t.string :name, null: false
      t.string :cable_colour, null: false

      t.timestamps null: false
    end
  end
end
