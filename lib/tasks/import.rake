
require_relative '../import'

namespace :alces do
  task import: :environment do
    Import.run
  end

  namespace :import do
    # XXX Quick sanity check that the expected number of things imported. Will
    # only work in environment exactly like the one I'm developing in, but good
    # enough for now.
    task sanity_check: :environment do
      {
        Chassis => 12,
        Gender => 8,
        Group => 4,
        Network => 2,
        NetworkAdapter => 52,
        NetworkAdapterPort => 208,
        NetworkSwitch => 2,
        Node => 26,
        Psu => 24,
        Server => 26,
      }.each do |klass, expected_number|
        number = klass.all.size
        unless number == expected_number
          abort <<~EOF.squish
            Expected #{expected_number} but only found #{number}
            #{klass.to_s.downcase.pluralize}!
          EOF
        end
      end
    end
  end
end
