class HomeController < ApplicationController
  def index
    flash.now[:notice] = "Welcome to FanPilot! This is a test flash message."
  end
end
