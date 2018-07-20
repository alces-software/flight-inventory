class CreateOobs < ActiveRecord::Migration[5.2]
  def change
    create_table :oobs do |t|
      t.json :data, null: false
      t.references :network, null: false

      t.timestamps null: false
    end

    add_reference :network_switches, :oob, null: false, foreign_key: true
    add_reference :servers, :oob, null: false, foreign_key: true
  end
end
