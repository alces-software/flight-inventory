class NetworkSwitch < ApplicationRecord
  belongs_to :oob
  has_many :network_connections
end
