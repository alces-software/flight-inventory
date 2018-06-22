class Node < ApplicationRecord
  belongs_to :server
  belongs_to :group
end
