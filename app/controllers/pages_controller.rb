class PagesController < ApplicationController
  def root
    @chassis = Chassis.all
    @switches = NetworkSwitch.all
  end
end
