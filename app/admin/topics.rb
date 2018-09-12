ActiveAdmin.register Topic do

  permit_params :title, :body, :category_id, :pinned, :locked, :noteworthy, :see_to_all
  
end
