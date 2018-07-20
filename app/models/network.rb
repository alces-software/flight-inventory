class Network < ApplicationRecord
  # Networks contain connections from the NetworkAdapters of Servers, via a
  # particular NetworkAdapterPort and NetworkAdapterSwitch (which also may
  # provide a particular Node with access to this Network).
  has_many :network_connections

  # They may also contain connections from the OOBs of Servers, NetworkSwitches
  # etc. (this is typically only the case for the management Network).
  #
  # Technically this works in a similar way to other connections, with OOBs
  # having a network adapter with a port which is connected to the Network
  # using a switch, but in this case this is much simpler and we do not capture
  # this information in Metalware or represent it in our data model here; it is
  # sufficient to just associate each OOB with the single Network it is
  # connected to directly.
  has_many :oobs
end
