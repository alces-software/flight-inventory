class PagesController < ApplicationController
  def root
    # Eager load app so get all descendants of ApplicationRecord, not just
    # those which happen to already be loaded.
    # XXX May be a better way to do this; possibly just glob and load the
    # models which exist, rather than entire app?
    Rails.application.eager_load!

    asset_classes = ApplicationRecord.descendants

    # XXX Camelize JSON recursively, rather than just top-level keys, so can
    # always just deal with camelCase keys client-side.
    @asset_data = asset_classes.map do |asset_class|
      [
        asset_class.to_s.camelize(:lower).pluralize,
        asset_class.all
      ]
    end.to_h
  end
end
