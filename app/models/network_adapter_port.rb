class NetworkAdapterPort < ApplicationRecord
  belongs_to :network_adapter

  # Can be nil if the port isn't connected to a network.
  has_one :network_connection

  # XXX Remove default scope from ApplicationRecord to order by non-existent
  # (for this model) `name` field - should probably only define that where it's
  # relevant.
  default_scope { unscope(:order) }
end
