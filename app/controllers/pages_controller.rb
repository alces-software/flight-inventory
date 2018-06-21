class PagesController < ApplicationController
  ASSET_TYPES =[
    Chassis,
    NetworkAdapter,
    Node,
    Psu,
    Server,
  ]

  def root
    @asset_data = ASSET_TYPES.map do |asset_class|
      [
        asset_class.to_s.camelize(:lower).pluralize,
        asset_class.all
      ]
    end.to_h
  end
end
