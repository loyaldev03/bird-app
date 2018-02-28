class HomeController < ApplicationController
  def index
    @slider = SliderImage.all
  end

  def about
  end

end
