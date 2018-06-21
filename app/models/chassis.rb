class Chassis < ApplicationRecord
  has_many :servers
  has_many :psus
end
