class NetworkAdapterPort < ApplicationRecord
  belongs_to :network_adapter

  # Can be nil if the port isn't connected to a network.
  has_one :network_connection
end
