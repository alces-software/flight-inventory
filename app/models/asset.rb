# Junk?

class Asset < ApplicationRecord
  # Disable STI on `type` column, for now at least (see
  # https://stackoverflow.com/a/29663933/2620402).
  self.inheritance_column = nil
end
