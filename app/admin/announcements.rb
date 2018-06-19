ActiveAdmin.register Announcement do
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
  permit_params :avatar, :user_id, :release_id, :title, :text

  before_save do |recource|
    recource.user_id = current_user.id unless current_user.has_role?(:admin)
  end
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

end
