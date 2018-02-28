class HomeController < ApplicationController
  def index
    @slider = SliderImage.all.ordered
  end

  def about
  end

end
