class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  default_scope { order(:name) }

  # XXX Should probably be in concern since only applicable to physical assets.
  def full_model
    [
      data['manufacturer'],
      data['model'],
    ].join(' ')
  end
end
