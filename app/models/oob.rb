
# Represents out-of-band management for Servers, NetworkSwitches etc.; AKA BMC
# when for a Server.
class Oob < ApplicationRecord
  # We store OOB-asset relationship within the asset rather than the OOB since
  # assets with an OOB must have this, whereas the OOB will only have one of
  # these assets associated, therefore this means this constraint can simply be
  # enforced at the database level via a non-nullable `oob_id` column; this
  # also avoids `oobs` having a proliferation of `${asset}_id` columns,
  # all but one of which will always be null.
  #
  # XXX Validate precisely one of these relations is present here?
  has_one :server
  has_one :network_switch
  has_one :pdu

  belongs_to :network
end
