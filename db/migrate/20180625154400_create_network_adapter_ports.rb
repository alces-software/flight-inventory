class CreateNetworkAdapterPorts < ActiveRecord::Migration[5.2]
  def change
    create_table :network_adapter_ports do |t|
      t.string :interface, null: false
      t.references :network_adapter, foreign_key: true, null: false

      t.timestamps null: false
    end
  end
end
