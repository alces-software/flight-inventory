
# Represents a single connection of a NetworkAdapter to a Network, via a
# particular NetworkAdapterPort and NetworkSwitch.
class NetworkConnection < ApplicationRecord
  belongs_to :network
  belongs_to :network_adapter_port
  belongs_to :network_switch
end
