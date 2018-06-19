ActiveAdmin.register Video do
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
  permit_params :title, :video_link, :comments_count, :shares_count, :user_id

  before_save do |recource|
    recource.user_id = current_user.id unless current_user.has_role?(:admin)
  end
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.actions
    
    f.inputs do
      f.input :title
      f.input :video_link
      # f.input :user_id, :input_html => { :value => current_user.id}, as: :hidden
    end
    f.actions
  end

end
