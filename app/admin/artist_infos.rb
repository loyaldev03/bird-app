ActiveAdmin.register ArtistInfo do
  config.filters = false

  jcropable

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
  permit_params :bio_short, :bio_long, :facebook, :twitter, 
      :instagram, :video, :genre, :followers_count, :tracks_count,
      :image, :artist_id

  before_save do |recource|
    recource.artist_id = current_user.id unless current_user.has_role?(:admin)
  end
#
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
      f.input :bio_short
      f.input :bio_long
      f.input :facebook
      f.input :twitter
      f.input :instagram
      f.input :genre
      f.input :image, hint: image, as: :jcropable
      f.input :image_cache, as: :hidden
    end

    f.actions
  end

end
