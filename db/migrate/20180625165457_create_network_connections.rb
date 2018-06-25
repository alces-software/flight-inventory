class CreateNetworkConnections < ActiveRecord::Migration[5.2]
  def change
    create_table :network_connections do |t|
      t.references :network_adapter_port, null: false
      t.references :network_switch, null: false
      t.references :network, null: false

      t.timestamps null: false
    end
  end
end
