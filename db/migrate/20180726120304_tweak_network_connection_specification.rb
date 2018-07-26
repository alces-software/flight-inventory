class TweakNetworkConnectionSpecification < ActiveRecord::Migration[5.2]
  def change
    # Move interface to be stored on the connection, since this is a property
    # of the Node's connection to a network via a port rather than a property
    # of the port itself.
    remove_column :network_adapter_ports, :interface, :string, null: false
    add_column :network_connections, :interface, :string, null: true

    # Now want to save the port number.
    add_column :network_adapter_ports, :number, :integer, null: false
  end
end
