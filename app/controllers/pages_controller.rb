class PagesController < ApplicationController
  def root
    @chassis = Chassis.all
  end
end
