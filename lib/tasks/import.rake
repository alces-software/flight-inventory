
require_relative '../import'

namespace :alces do
  task import: :environment do
    Import.run
  end
end
