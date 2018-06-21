class CreateNetworkAdapters < ActiveRecord::Migration[5.2]
  def change
    create_table :network_adapters do |t|
      t.string :name, null: false
      t.json :data, null: false

      t.references :server, foreign_key: true
      t.timestamps null: false
    end
  end
end
