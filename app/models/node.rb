class Node < ApplicationRecord
  belongs_to :server
  belongs_to :group
  has_and_belongs_to_many :genders
end
