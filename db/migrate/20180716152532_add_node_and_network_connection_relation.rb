class AddNodeAndNetworkConnectionRelation < ActiveRecord::Migration[5.2]
  def change
    add_reference :network_connections, :node, foreign_key: true, null: true
  end
end
