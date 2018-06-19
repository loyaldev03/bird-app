ActiveAdmin.register TopicCategoryGroup do
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
  permit_params :title, :prior, :image, 
      categories_attributes: [:id, :title, :prior, :image, :group, :_destroy]

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
      image = f.object.image.present? ? image_tag(f.object.image.url, style: "background-color: gray;") : ''
      f.input :title
      f.input :image, hint: image
      f.input :image_cache, as: :hidden
      f.input :prior
    end

    f.inputs do
      f.has_many :categories do |t|
        c_image = f.object.image.present? ? image_tag(f.object.image.url) : ''
        t.input :title
        t.input :image, hint: c_image, as: :jcropable
        t.input :image_cache, as: :hidden
        t.input :prior
      end
    end

    f.actions
  end

end

ActiveAdmin.register TopicCategory do
  menu false
  jcropable
end