ActiveAdmin.register SliderImage do
  config.filters = false
  
  permit_params :image, :priority, :text

end
