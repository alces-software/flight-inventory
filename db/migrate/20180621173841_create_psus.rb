class CreatePsus < ActiveRecord::Migration[5.2]
  def change
    create_table :psus do |t|
      t.string :name, null: false
      t.json :data, null: false

      t.references :chassis, foreign_key: true
      t.timestamps null: false
    end
  end
end
