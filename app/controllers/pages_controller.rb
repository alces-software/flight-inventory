class PagesController < ApplicationController
  ASSET_TYPES =[
    Chassis,
    Node,
    Server,
  ]

  def root
    @asset_data = ASSET_TYPES.map do |asset_class|
      [
        asset_class.to_s.downcase.pluralize,
        asset_class.all
      ]
    end.to_h
  end
end
