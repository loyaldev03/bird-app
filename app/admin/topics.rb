ActiveAdmin.register Topic do

  permit_params :title, :text, :category_id, :see_to_all
  
end
