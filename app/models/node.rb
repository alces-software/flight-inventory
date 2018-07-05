class Node < ApplicationRecord
  belongs_to :server
  belongs_to :group
  has_and_belongs_to_many :genders

  def as_json(_options)
    super.merge(genders: genders.map(&:name))
  end
end
