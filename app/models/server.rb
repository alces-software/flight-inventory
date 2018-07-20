class Server < ApplicationRecord
  has_many :nodes
  has_many :network_adapters
  belongs_to :chassis
  belongs_to :oob
end
