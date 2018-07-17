
# Represents a single connection of a NetworkAdapter to a Network, via a
# particular NetworkAdapterPort and NetworkSwitch, and optionally with a Node
# having access to this connection.
class NetworkConnection < ApplicationRecord
  belongs_to :network
  belongs_to :network_adapter_port
  belongs_to :network_switch
  belongs_to :node, optional: true

  # XXX Remove default scope from ApplicationRecord to order by non-existent
  # (for this model) `name` field - should probably only define that where it's
  # relevant.
  default_scope { unscope(:order) }
end
