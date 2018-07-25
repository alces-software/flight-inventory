class CreatePdus < ActiveRecord::Migration[5.2]
  def change
    create_table :pdus do |t|
      t.string :name, null: false
      t.json :data, null: false
      t.references :oob, null: false, foreign_key: true

      t.timestamps null: false
    end
  end
end
