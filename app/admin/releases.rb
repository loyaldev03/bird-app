ActiveAdmin.register Release do
  filter :title
  filter :artist

  permit_params :title, :artist, :catalog, :text, :avatar, :facebook_img,
    :published_at, :upc_code, :compilation, :release_type, :buy_uri,
    :release_date, :artist_as_string,
    user_ids: [], tracks_attributes: [:id, :title, :release, :track_number,
    :genre, :isrc_code, :uri_string, :sample_uri, :artist, :_destroy,
    :artist_as_string, user_ids: [],
    track_info_attributes: [:id, :label_name,  :catalog,
                            :release_artist, :track_title,
                            :track_artist, :release_name,
                            :release_date, :mix_name,
                            :remixer, :track_time,
                            :barcode, :isrc,
                            :genre, :release_written_by,
                            :release_producer, :track_publisher,
                            :track_written_by, :track_produced_by,
                            :vocals_m, :vocals_f,
                            :upbeat_drivind_energetic, :sad_moody_dark,
                            :fun_playfull_quirky, :sentimental_love,
                            :big_buildups_sweeps, :celebratory_party_vibe,
                            :inspiring_uplifting, :chill_mellow,
                            :lyrics]]

  config.sort_order = 'created_at_desc'
  jcropable

  index do
    selectable_column
    column :title
    column :artist
    column "Attached Artists" do |release|
      images = ""

      release.users.each do |user|
        images << "<a href='/artists/#{user.id}' title='#{user.name}' target='_blank'><img src='#{user.avatar.thumb.url}' class='small-avatar'></a>"
      end

      images.html_safe
    end
    column :available_to_all
    column :release_date
    column :published_at
    column (:downloads) { |obj| obj.downloads.count }

    actions do |release|
      item "Encode", encode_admin_release_path(release), class: "member_link"
    end
  end

  show do
    panel "Release" do
      h3 "#{release.title} - #{release.artist}"

      div do
        img release.avatar
      end
      div 'Release date: ' + release.release_date.strftime('%D') if release.release_date
      div 'Catalog: ' + release.catalog
      div 'UPC code: ' + release.upc_code
      div ('Text: ' + release.text).html_safe

      table_for release.tracks do
        column :track_number
        column :title
        column :artist
        column :uri
        column :sample_uri
        column (:downloads) { |obj| obj.downloads.count }
      end
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.actions

    f.inputs do
      image = f.object.avatar.present? ? image_tag(f.object.avatar.url) : ''
      f.input :avatar, hint: image_tag(f.object.avatar.url(:large))
      f.input :avatar_cache, as: :hidden
      f.input :facebook_img
      f.input :title
      f.input :catalog
      f.input :text, as: :quill_editor, input_html: {data: {options: {modules: {toolbar: [['bold', 'italic', 'underline'], ['link']]}, placeholder: 'Type something...', theme: 'snow'}}}
      f.input :upc_code
      f.input :compilation
      f.input :release_type
      f.input :buy_uri
      f.input :published_at, as: :date_time_picker
      f.input :release_date, as: :date_time_picker
      f.input :users, as: :select, label: "Artists",
          collection: User.with_role(:artist).map {|a| [a.name, a.id] }
      f.input :artist_as_string
      f.input :artist
    end

    f.inputs do
      f.has_many :tracks, class: "directUpload" do |t|
        t.input :track_number
        t.input :title
        t.input :genre
        t.input :isrc_code
        t.input :uri_string, as: :hidden
        t.input :file, as: :file, label: "Track file (WAV Format)", input_html: { class: 'direct-upload' }
        t.input :users, as: :select, label: "Artists",
        collection: User.with_role(:artist).map {|a| [a.name, a.id] }
        t.input :artist_as_string
        t.input :artist

        t.has_many :track_info, allow_destroy: true, new_record: false, class: "directUpload" do |x|
          x.input :label_name
          x.input :catalog
          x.input :release_artist
          x.input :track_title
          x.input :track_artist
          x.input :release_name
          x.input :release_date, as: :date_time_picker
          x.input :mix_name
          x.input :remixer
          x.input :track_time
          x.input :barcode
          x.input :isrc
          x.input :genre
          x.input :release_written_by
          x.input :release_producer
          x.input :track_publisher
          x.input :track_written_by
          x.input :track_produced_by
          x.input :vocals_m
          x.input :vocals_f
          x.input :upbeat_drivind_energetic
          x.input :sad_moody_dark
          x.input :fun_playfull_quirky
          x.input :sentimental_love
          x.input :big_buildups_sweeps
          x.input :celebratory_party_vibe
          x.input :inspiring_uplifting
          x.input :chill_mellow
          x.input :lyrics
        end
      end
    end
    f.actions
  end

  member_action :encode, method: :get do
    @s3_direct_post = S3_BUCKET.presigned_post(
      key: "uploads/tracks/#{SecureRandom.uuid}/${filename}",
      success_action_status: '201',
      acl: 'public-read'
    )
    resource.encode
    redirect_to resource_path, notice: "Encoding Release! This may take up to 10 minutes."
  end

  batch_action :attach_artists_to, form: {
    user: User.with_role(:artist).map { |u| [u.name, u.id] }
  } do |ids, inputs|
    ids.each do |id|
      release = Release.find id
      release.users << User.find(inputs["user"])
    end
    redirect_to admin_releases_path
  end

  batch_action :destroy, false

end
