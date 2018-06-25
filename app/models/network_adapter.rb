class NetworkAdapter < ApplicationRecord
  belongs_to :server
  has_many :network_adapter_ports
end
