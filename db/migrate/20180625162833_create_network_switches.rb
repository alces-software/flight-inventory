class CreateNetworkSwitches < ActiveRecord::Migration[5.2]
  def change
    create_table :network_switches do |t|
      t.string :name, null: false
      t.json :data, null: false

      t.timestamps null: false
    end
  end
end
