class CreateNotifications < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.boolean :sounds_option, default: true
      t.boolean :desktop_option, default: true
      t.boolean :global_email_notification, default: true
      t.boolean :important_notification, default: true
      t.boolean :newsletter, default: true
      t.boolean :gaming_activities, default: true
      t.boolean :new_friend_request_alert, default: true
      t.boolean :new_friend_request_email, default: true
      t.boolean :new_favorite_alert, default: true
      t.boolean :new_favorite_email, default: true
      t.boolean :someone_comments_feed_you_follow_alert, default: true
      t.boolean :someone_comments_feed_you_follow_email, default: true
      t.boolean :user_replies_to_your_comment_alert, default: true
      t.boolean :user_replies_to_your_comment_email, default: true
      t.boolean :user_follows_topic_you_created_alert, default: true
      t.boolean :user_follows_topic_you_created_email, default: true
      t.boolean :new_friend_request_alert, default: true
      t.boolean :new_friend_request_email, default: true
      t.boolean :friend_comment_on_feed_alert, default: true
      t.boolean :friend_comment_on_feed_email, default: true
      t.boolean :friend_follows_feed_alert, default: true
      t.boolean :friend_follows_feed_email, default: true
      t.boolean :new_playlist_follower_alert, default: true
      t.boolean :new_playlist_follower_email, default: true

      t.timestamps
    end
  end
end
