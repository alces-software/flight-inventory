class CreateChassis < ActiveRecord::Migration[5.2]
  def change
    create_table :chassis do |t|
      t.string :name, null: false
      t.json :data, null: false

      t.timestamps null: false
    end

    add_reference :servers, :chassis, foreign_key: true
  end
end
