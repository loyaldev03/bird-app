ActiveAdmin.register User do
  permit_params :email, :password, :password_confirmation, :avatar, 
      :avatar_cache, :shipping_address, :birthdate, :gender, :t_shirt_size, 
      :subscription_type, :first_name, :last_name, :city, #:subscription,
      track_ids: [], role_ids: [], release_ids: [],
      artist_info_attributes: [:id, :bio_short, :bio_long, :facebook, :twitter, 
      :instagram, :video, :genre, :user, :_destroy]

  jcropable

  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.actions
    
    f.inputs do
      f.input :avatar, hint: image_tag(f.object.avatar.url(:thumb)), as: :jcropable
      f.input :avatar_cache, as: :hidden
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :password
      f.input :password_confirmation

      if current_user.has_role?(:admin)
        f.input :roles, as: :check_boxes
        f.input :subscription_type
        f.input :braintree_subscription_expires_at, as: :date_time_picker
      end
      
      f.input :city
      f.input :shipping_address
      f.input :birthdate, as: :date_time_picker
      f.input :gender
      f.input :t_shirt_size
      f.input :releases
      f.input :tracks
    end

    f.inputs do
      f.has_many :artist_info do |s|
        image = s.object.image.present? ? image_tag(s.object.image.url, style: "background-color: gray;") : ''
        s.input :bio_short
        s.input :bio_long
        s.input :facebook
        s.input :twitter
        s.input :instagram
        s.input :genre
        s.input :image, hint: image, as: :jcropable
        s.input :image_cache, as: :hidden
      end
    end

    f.actions
  end

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete "password"
        params[:user].delete "password_confirmation"
      end

      if params[:user][:avatar].present?


      end
      super
    end
  end

end
