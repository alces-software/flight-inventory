class CreateNodes < ActiveRecord::Migration[5.2]
  def change
    create_table :nodes do |t|
      t.string :name, null: false
      t.json :data, null: false
    end
  end
end
