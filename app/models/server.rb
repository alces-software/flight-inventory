class Server < ApplicationRecord
  has_many :nodes
  belongs_to :chassis
end
