class PagesController < ApplicationController
  def root
    @asset_data = {
      servers: Server.all,
      nodes: Node.all,
    }
  end
end
