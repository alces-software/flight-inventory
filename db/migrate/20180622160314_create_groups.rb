class CreateGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.json :data, null: false

      t.timestamps null: false
    end

    add_reference :nodes, :group, foreign_key: true
  end
end
