class BirdOldMerge
    class << self
      def test
        puts 'hello world'
      end



    def users

    #   #users
    #   create_table "users", id: :serial, force: :cascade do |t|
    #     t.string "email", default: "", null: false
    #     t.string "encrypted_password", default: "", null: false
    #     t.string "reset_password_token"
    #     t.datetime "reset_password_sent_at"
    #     t.datetime "remember_created_at"
    #     t.integer "sign_in_count", default: 0, null: false
    #     t.datetime "current_sign_in_at"
    #     t.datetime "last_sign_in_at"
    #     t.string "current_sign_in_ip"
    #     t.string "last_sign_in_ip"
    #     t.string "confirmation_token"
    #     t.datetime "confirmed_at"
    #     t.datetime "confirmation_sent_at"
    #     t.string "unconfirmed_email"
    #     t.datetime "created_at", null: false
    #     t.datetime "updated_at", null: false
    #     t.string "provider"
    #     t.string "uid"
    #     t.string "first_name"
    #     t.string "last_name"
    #     t.string "image_uri"
    #     t.datetime "deleted_at"
    #     t.integer "subscription_type", default: 0, null: false
    #     t.string "invitation_token"
    #     t.datetime "invitation_created_at"
    #     t.datetime "invitation_sent_at"
    #     t.datetime "invitation_accepted_at"
    #     t.integer "invitation_limit"
    #     t.integer "invited_by_id"
    #     t.string "invited_by_type"
    #     t.integer "invitations_count", default: 0
    #     t.string "braintree_customer_id"
    #     t.string "braintree_subscription_id"
    #     t.date "braintree_subscription_expires_at"
    #     t.string "address_line_1"
    #     t.string "address_line_2"
    #     t.string "address_city"
    #     t.string "address_state"
    #     t.string "address_zip"
    #     t.string "address_country"
    #     t.string "shirt_size"
    #     t.integer "likees_count", default: 0
    #     t.boolean "subscribed", default: false
    #     t.boolean "subscribed_to_topic_comments", default: true
    #     t.boolean "subscribed_to_comment_replies", default: true
    #     t.boolean "subscribed_to_likes", default: false
    #     t.date "subscription_started_at"
    #     t.integer "subscription_length", default: 0, null: false
    #     t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    #     t.index ["deleted_at"], name: "index_users_on_deleted_at"
    #     t.index ["email"], name: "index_users_on_email", unique: true
    #     t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    #     t.index ["invitations_count"], name: "index_users_on_invitations_count"
    #     t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    #     t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    #   end

    # create_table "users", force: :cascade do |t|
    #   t.string "email", default: "", null: false
    #   t.string "encrypted_password", default: "", null: false
    #   t.string "reset_password_token"
    #   t.datetime "reset_password_sent_at"
    #   t.datetime "remember_created_at"
    #   t.integer "sign_in_count", default: 0, null: false
    #   t.datetime "current_sign_in_at"
    #   t.datetime "last_sign_in_at"
    #   t.inet "current_sign_in_ip"
    #   t.inet "last_sign_in_ip"
    #   t.datetime "created_at", null: false
    #   t.datetime "updated_at", null: false
    #   t.string "first_name"
    #   t.string "avatar"
    #   t.string "braintree_customer_id"
    #   t.string "shipping_address"
    #   t.datetime "birthdate"
    #   t.integer "gender"
    #   t.string "t_shirt_size"
    #   t.integer "subscription_type"
    #   t.string "provider"
    #   t.string "uid"
    #   t.datetime "subscription_started_at"

    #   t.string "braintree_subscription_id"
    #   t.date "braintree_subscription_expires_at"
    #   t.date "subscription_started_at"
    #   t.integer "subscription_length", default: 0, null: false
    
    #   t.string "city"
    #   t.string "last_name"
    #   t.integer "old_id"
    #   t.boolean "drip_source"
    #   t.index ["email"], name: "index_users_on_email", unique: true
    #   t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    # end


      sql = "
        SELECT
          
          email,
          encrypted_password,
          reset_password_token,
          reset_password_sent_at,
          remember_created_at,
          sign_in_count,
          current_sign_in_at,
          last_sign_in_at,
          current_sign_in_ip,
          last_sign_in_ip,
          created_at,
          updated_at,
          image_uri,
          first_name,
          braintree_customer_id,
          braintree_subscription_id,
          braintree_subscription_expires_at,
          subscription_started_at,
          subscription_length,
          
          address_zip || ' ' || address_line_1 || '' || address_line_2 || ' ' || address_city || ' ' || address_state || ' ' || address_country as shipping_address,
          
          shirt_size as t_shirt_size,
          subscription_type,
          provider,
          uid,
          subscription_started_at,
          address_city as city,
          last_name,


          id as old_id

          --avatar,
          --birthdate,
          --gender,


        FROM
          users
      "

      users = BirdOldDb.connection.select_all(sql)

      
      BirdNewDb.table_name = "users"
      BirdNewDb.bulk_insert values: users

      restore_schema_cache

      puts 'users complete'

    end
    

    def tracks

#   #to tracks
#   create_table "tracks", id: :serial, force: :cascade do |t|
#     t.string "title"
#     t.string "uri"
#     t.datetime "created_at", null: false
#     t.datetime "updated_at", null: false
#     t.integer "release_id"
#     t.string "artist"
#     t.integer "track_number"
#     t.string "genre"
#     t.datetime "deleted_at"
#     t.string "isrc_code"
#     t.string "sample_uri"
#     t.string "waveform_image_uri"
#     t.index ["deleted_at"], name: "index_tracks_on_deleted_at"
#     t.index ["release_id"], name: "index_tracks_on_release_id"
#   end

  # create_table "tracks", force: :cascade do |t|
  #   t.string "title"
  #   t.string "uri"
  #   t.integer "release_id"
  #   t.integer "track_number"
  #   t.string "genre"
  #   t.string "isrc_code"
  #   t.string "sample_uri"
  #   t.string "waveform_image_uri"
  #   t.datetime "created_at", null: false
  #   t.datetime "updated_at", null: false
  #   t.string "avatar"
  #   t.integer "old_id"
  #   t.boolean "drip_source"
  # end


      sql = '
        SELECT
          title,
          uri,
          release_id,
          artist,
          track_number,
          genre,
          isrc_code,
          sample_uri,
          waveform_image_uri,
          created_at,
          updated_at,

          id as old_id

          --avatar,

        FROM
          tracks
      '
      tracks = BirdOldDb.connection.select_all(sql)

      new_release_id = Release.where(drip_source: nil).all.map{|e|[e.old_id,e.id]}.to_h

      tracks = tracks.map do |e|
          e["release_id"] = new_release_id[e["release_id"]]
          e
      end
      
      BirdNewDb.table_name = "tracks"
      BirdNewDb.bulk_insert values: tracks

      restore_schema_cache

      puts 'tracks complete'
    end

    def track_files
      sql = '
        SELECT
          *
        FROM
          track_files
      '

      track_files = BirdOldDb.connection.select_all(sql)

      new_track_id = Track.where(drip_source: nil).all.map{|e|[e.old_id,e.id]}.to_h

      track_files = track_files.map do |e|
          e["track_id"] = new_track_id[e["track_id"]]
          e
      end
      
      BirdNewDb.table_name = "track_files"
      BirdNewDb.bulk_insert values: track_files

      restore_schema_cache

      puts 'track_files complete'
    end

      def topics

          # create_table "topics", id: :serial, force: :cascade do |t|
          #   t.string "title"
          #   t.text "text"
          #   t.integer "likers_count", default: 0
          #   t.datetime "created_at", null: false
          #   t.datetime "updated_at", null: false
          #   t.datetime "deleted_at"
          #   t.integer "user_id"
          #   t.boolean "pinned", default: false
          #   t.boolean "locked", default: false
          #   t.index ["deleted_at"], name: "index_topics_on_deleted_at"
          #   t.index ["user_id"], name: "index_topics_on_user_id"
          # end

          # create_table "topics", force: :cascade do |t|
          #   t.string "title"
          #   t.text "text"
          #   t.integer "user_id"
          #   t.boolean "pinned"
          #   t.boolean "locked"
          #   t.datetime "created_at", null: false
          #   t.datetime "updated_at", null: false
          #   t.integer "category_id"
          #   t.integer "old_id"
          # end

        sql = '
          SELECT
            title,
            text as body,
            user_id,
            pinned,
            locked,
            created_at,
            updated_at,
            
            id as old_id

            --category_id,
          FROM
            topics
        '
        
        topics = BirdOldDb.connection.select_all(sql)
        
        # #хэш вида old_id=>id
        new_user_id = User.where(drip_source: nil).all.map{|e|[e.old_id,e.id]}.to_h
        
        topics = topics.map do |e|
            e["user_id"] = new_user_id[e["user_id"]]
            e
        end


        BirdNewDb.table_name = "topics"
        BirdNewDb.bulk_insert values: topics

        restore_schema_cache

        puts 'topics complete'
      end


      def topic_tags_topics
        sql = '
          SELECT
            *
          FROM
            topic_tags_topics
        '

        topic_tags_topics = BirdOldDb.connection.select_all(sql)


        #хэш вида old_id=>id
        new_topic_id = Topic.all.map{|e|[e.old_id,e.id]}.to_h

        topic_tags_topics = topic_tags_topics.map do |e|
            e["topic_id"] = new_topic_id[e["topic_id"]]
            e
        end

        
        BirdNewDb.table_name = "topic_tags_topics"
        BirdNewDb.bulk_insert values: topic_tags_topics

        restore_schema_cache

        puts 'topic_tags_topics complete'
      end


      def topic_tags
        sql = '
          SELECT
            *
          FROM
            topic_tags
        '
        topic_tags = BirdOldDb.connection.select_all(sql)

        
        BirdNewDb.table_name = "topic_tags"
        BirdNewDb.bulk_insert values: topic_tags

        restore_schema_cache

        puts 'topic_tags complete'
      end


      def releases

        # create_table "releases", id: :serial, force: :cascade do |t|
        #   t.string "title"
        #   t.string "artist"
        #   t.string "catalog"
        #   t.text "text"
        #   t.string "image_uri"
        #   t.datetime "created_at", null: false
        #   t.datetime "updated_at", null: false
        #   t.datetime "published_at"
        #   t.datetime "deleted_at"
        #   t.string "upc_code"
        #   t.string "buy_uri"
        #   t.boolean "compilation", default: false
        #   t.boolean "available_to_all", default: false
        #   t.date "release_date"
        #   t.integer "encode_status"
        #   t.datetime "encoded_at"
        #   t.integer "likers_count", default: 0
        #   t.integer "email_id"
        #   t.string "facebook_img"
        #   t.index ["deleted_at"], name: "index_releases_on_deleted_at"
        #   t.index ["email_id"], name: "index_releases_on_email_id"
        # end

          # create_table "releases", force: :cascade do |t|
          #   t.string "title"
          #   t.string "catalog"
          #   t.text "text"
          #   t.string "avatar"
          #   t.string "facebook_img"
          #   t.datetime "published_at"
          #   t.string "upc_code"
          #   t.boolean "compilation"
          #   t.datetime "release_date"
          #   t.datetime "created_at", null: false
          #   t.datetime "updated_at", null: false
          #   t.boolean "available_to_all"
          #   t.integer "old_id"
          #   t.boolean "drip_source"
          # end


        sql = '
          SELECT
            title,
            artist,
            catalog,
            text,
            facebook_img,
            published_at,
            upc_code,
            compilation,
            release_date,
            created_at,
            updated_at,
            available_to_all,
            image_uri,
            id as old_id

            --avatar TODO: load from image_uri
          FROM
            releases
        '

        releases = BirdOldDb.connection.select_all(sql)


        
        BirdNewDb.table_name = "releases"
        BirdNewDb.bulk_insert values: releases

        restore_schema_cache

        puts 'releases complete'
      end

      def release_files
        sql = '
          SELECT
            *
          FROM
            release_files
        '

        release_files = BirdOldDb.connection.select_all(sql)


        #хэш вида old_id=>id
        # TODO exclude drip_source ?
        new_release_id = Release.where(drip_source: nil).all.map{|e|[e.old_id,e.id]}.to_h

        release_files = release_files.map do |e|
            e["release_id"] = new_release_id[e["release_id"]]
            e
        end

        
        BirdNewDb.table_name = "release_files"
        BirdNewDb.bulk_insert values: release_files

        restore_schema_cache

        puts 'release_files complete'
      end


      def posts

        # TODO: not found user id and release id

          #to announcements
          # create_table "posts", id: :serial, force: :cascade do |t|
          #   t.string "title"
          #   t.text "text"
          #   t.string "image_uri"
          #   t.datetime "published_at"
          #   t.datetime "created_at", null: false
          #   t.datetime "updated_at", null: false
          #   t.datetime "deleted_at"
          #   t.integer "likers_count", default: 0
          #   t.integer "email_id"
          #   t.string "facebook_img"
          #   t.index ["deleted_at"], name: "index_posts_on_deleted_at"
          #   t.index ["email_id"], name: "index_posts_on_email_id"
          # end

          # create_table "announcements", force: :cascade do |t|
          #   t.integer "user_id"
          #   t.integer "release_id"
          #   t.string "title"
          #   t.text "text"
          #   t.string "avatar"
          #   t.datetime "created_at", null: false
          #   t.datetime "updated_at", null: false
          # end

        sql = '
          SELECT
            id as old_id,
            title,
            text,
            image_uri,
            created_at,
            updated_at,
            NULL as user_id,
            NULL as release_id
          FROM
            posts
        '

        posts = BirdOldDb.connection.select_all(sql)

        #хэш вида old_id=>id
        # new_user_id = User.where(drip_source: nil).all.map{|e|[e.old_id,e.id]}.to_h

        # posts = posts.map do |e|
        #     e.delete("id")
        #     e["user_id"] = new_user_id[e["user_id"]]
        #     e
        # end

        BirdNewDb.table_name = "announcements"
        BirdNewDb.bulk_insert values: posts

        restore_schema_cache

        puts 'posts complete'

      end


      def meta_tags
        # TODO: check resources
        
        # - post
        # - chirp
        # - release


        sql = '
          SELECT
            *
          FROM
            meta_tags
        '

        meta_tags = BirdOldDb.connection.select_all(sql)
        
        new_release_id = Release.where(drip_source: nil).all.map{|e|[e.old_id,e.id]}.to_h
        new_post_id = Announcement.all.map{|e|[e.old_id,e.id]}.to_h
        new_topic_id = Topic.all.map{|e|[e.old_id,e.id]}.to_h


        meta_tags = meta_tags.map do |e|
        #     e.delete("id")
              if(e["resource_type"]=='release')
                e["resource_id"] = new_release_id[ e["resource_id"] ]
                e["resource_type"] = "Release"
              elsif (e["resource"]=='chirp')
                e["resource_id"] = new_topic_id[e["resource_id"]]
                e["resource_type"] = "Topic"
              elsif (e["resource"]=='post')
                e["resource_id"] = new_post_id[e["resource_id"]]
                e["resource_type"] = "Announcement"
              end            
        #     e["user_id"] = new_user_id[e["user_id"]]
            e
        end

        BirdNewDb.table_name = "meta_tags"
        BirdNewDb.bulk_insert values: meta_tags

        restore_schema_cache

        puts 'meta_tags complete, RELEASE ONLY!'
      end



      def emails_users
        sql = '
          SELECT
            *
          FROM
            emails_users
        '

        emails_users = BirdOldDb.connection.select_all(sql)
        
        #хэш вида old_id=>id
        new_user_id = User.where(drip_source: nil).all.map{|e|[e.old_id,e.id]}.to_h



        emails_users = emails_users = emails_users.map do |e|
            e["user_id"] = new_user_id[e["user_id"]]
            e
        end

        BirdNewDb.table_name = "emails_users"
        BirdNewDb.bulk_insert values: emails_users

        restore_schema_cache

        puts 'emails_users complete'
      end

      def emails
        sql = '
          SELECT
            *
          FROM
            emails
        '

        emails = BirdOldDb.connection.select_all(sql)
        
        BirdNewDb.table_name = "emails"
        BirdNewDb.bulk_insert values: emails

        restore_schema_cache

        puts 'emails complete'
      end

      def drip_users
          # create_table "drip_users", id: :serial, force: :cascade do |t|
          #   t.datetime "join_date"
          #   t.boolean "active"
          #   t.integer "months_active"
          #   t.integer "credits"
          #   t.string "full_name"
          #   t.string "username"
          #   t.string "email"
          #   t.string "street_address"
          #   t.string "city"
          #   t.string "state"
          #   t.string "postal_code"
          #   t.string "country"
          # end

          # create_table "users", force: :cascade do |t|
          #   t.string "email", default: "", null: false
          #   t.string "encrypted_password", default: "", null: false
          #   t.string "reset_password_token"
          #   t.datetime "reset_password_sent_at"
          #   t.datetime "remember_created_at"
          #   t.integer "sign_in_count", default: 0, null: false
          #   t.datetime "current_sign_in_at"
          #   t.datetime "last_sign_in_at"
          #   t.inet "current_sign_in_ip"
          #   t.inet "last_sign_in_ip"
          #   t.datetime "created_at", null: false
          #   t.datetime "updated_at", null: false
          #   t.string "first_name"
          #   t.string "avatar"
          #   t.string "braintree_customer_id"
          #   t.string "shipping_address"
          #   t.datetime "birthdate"
          #   t.integer "gender"
          #   t.string "t_shirt_size"
          #   t.integer "subscription_type"
          #   t.string "provider"
          #   t.string "uid"
          #   t.datetime "subscription_started_at"
          #   t.string "city"
          #   t.string "last_name"
          #   t.integer "old_id"
          #   t.boolean "drip_source"
          #   t.index ["email"], name: "index_users_on_email", unique: true
          #   t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
          # end
        
        sql = "
          SELECT
            join_date as created_at,
            full_name as last_name, --TODO: parse via space
            '$2a$11$pSIMAIwMw4AofGResqdKiuTBlK5B26flHDC82nr3Wh5U1kxO1Mnaq' as encrypted_password, --TODO: manage password
            email,
            username as uid,
            postal_code || ' ' || street_address || ' ' || city || ' ' || state || ' ' || country as shipping_address,
            city,
            id as old_id,
            true as drip_source


          FROM
            drip_users
        "
        drip_users = BirdOldDb.connection.select_all(sql)

        User.bulk_insert values: drip_users
        restore_schema_cache
        puts 'drip_users complete'

      end

      def drip_tracks
          # create_table "drip_tracks", id: :serial, force: :cascade do |t|
          #   t.integer "drip_release_id"
          #   t.string "artist"
          #   t.string "title"
          #   t.string "isrc_code"
          #   t.integer "duration"
          #   t.integer "track_number"
          #   t.string "state"
          #   t.datetime "created_at", null: false
          #   t.datetime "updated_at", null: false
          #   t.index ["drip_release_id"], name: "index_drip_tracks_on_drip_release_id"
          # end

          # create_table "tracks", force: :cascade do |t|
          #   t.string "title"
          #   t.string "url"
          #   t.integer "release_id"
          #   t.integer "track_number"
          #   t.string "genre"
          #   t.string "isrc_code"
          #   t.string "sample_uri"
          #   t.string "waveform_image_uri"
          #   t.datetime "created_at", null: false
          #   t.datetime "updated_at", null: false
          #   t.string "avatar"
          #   t.integer "old_id"
          #   t.boolean "drip_source"
          # end
        
        sql = '
          SELECT
            title,
            drip_release_id as release_id,
            track_number,
            isrc_code,
            created_at,
            updated_at,
            
            id as old_id,
            true as drip_source

            -- url, 
            -- genre,
            -- sample_uri,
            -- waveform_image_uri
            -- avatar,
            -- 


          FROM
            drip_tracks
        '
        drip_tracks = BirdOldDb.connection.select_all(sql)
        

        #хэш вида old_id=>id
        new_release_id = Release.where(drip_source: true).all.map{|e|[e.old_id,e.id]}.to_h

        drip_tracks = drip_tracks.map do |e|
            e["release_id"] = new_release_id[e["release_id"]]
            e
        end

        Track.bulk_insert values: drip_tracks

        restore_schema_cache

        puts 'drip_tracks complete'


      end

      def downloads
        sql = '
          SELECT
            *
          FROM
            downloads
        '

        downloads = BirdOldDb.connection.select_all(sql)
        
        #хэш вида old_id=>id
        new_user_id = User.where(drip_source: nil).all.map{|e|[e.old_id,e.id]}.to_h
        new_track_id = Track.where(drip_source: nil).all.map{|e|[e.old_id,e.id]}.to_h

        downloads = downloads.map do |e|
            e.delete("id")
            e["user_id"] = new_user_id[e["user_id"]]
            e["track_id"] = new_track_id[e["track_id"]]
            e
        end

        BirdNewDb.table_name = "downloads"
        BirdNewDb.bulk_insert values: downloads

        restore_schema_cache

        puts 'downloads complete'
      end



      def drip_releases
        # create_table "drip_releases", id: :serial, force: :cascade do |t|
        #   t.string "artist"
        #   t.integer "year"
        #   t.string "catalog_number"
        #   t.string "upc_code"
        #   t.text "description"
        #   t.string "title"
        #   t.string "cover"
        #   t.string "state"
        #   t.string "buy_url"
        #   t.date "publish_at"
        #   t.datetime "created_at", null: false
        #   t.datetime "updated_at", null: false
        # end
        
        # create_table "releases", force: :cascade do |t|
        #   t.string "title"
        #   t.string "catalog"
        #   t.text "text"
        #   t.string "avatar"
        #   t.string "facebook_img"
        #   t.datetime "published_at"
        #   t.string "upc_code"
        #   t.boolean "compilation"
        #   t.datetime "release_date"
        #   t.datetime "created_at", null: false
        #   t.datetime "updated_at", null: false
        #   t.boolean "available_to_all"
        # end


        sql = '
          SELECT
            title,
            catalog_number as catalog,
            description as text,
            cover as facebook_img,
            upc_code,
            publish_at as release_date,
            created_at,
            updated_at,

            id as old_id,
            true as drip_source

            --published_at,
            --compilation,
            --available_to_all
          FROM
            drip_releases
        '
        drip_releases = BirdOldDb.connection.select_all(sql)
        
        Release.bulk_insert values: drip_releases

        restore_schema_cache

        puts 'drip_releases complete'

      end


      def restore_schema_cache

        BirdOldDb.connection.schema_cache.clear!
        BirdOldDb.reset_column_information
        
        BirdNewDb.connection.schema_cache.clear!
        BirdNewDb.reset_column_information
        
      end
  end
end