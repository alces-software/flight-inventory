class AddDataToNetworks < ActiveRecord::Migration[5.2]
  def change
    add_column :networks, :data, :json, null: false
  end
end
