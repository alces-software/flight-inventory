class PagesController < ApplicationController
  def root
    @asset_data = {
      chassis: Chassis.all,
      servers: Server.all,
      nodes: Node.all,
    }
  end
end
