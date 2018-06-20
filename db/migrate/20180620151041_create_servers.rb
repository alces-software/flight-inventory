class CreateServers < ActiveRecord::Migration[5.2]
  def change
    create_table :servers do |t|
      t.string :name, null: false
      t.json :data, null: false
    end

    add_reference :nodes, :server, foreign_key: true
  end
end
