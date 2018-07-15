ActiveAdmin.register Topic do

  permit_params :title, :body, :category_id, :see_to_all
  
end
