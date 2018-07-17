class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true
  
  after_create :add_points, :trigger_likes_count
  after_destroy :trigger_likes_count, :remove_points, :remove_from_feed

  
  include StreamRails::Activity
  as_activity

  def activity_notify
    notify = [StreamRails.feed_manager.get_feed( 'masterfeed', 1 )]

    if self.likeable.try(:users)
      self.likeable.users.each do |user|
        notify << StreamRails.feed_manager.get_notification_feed(user.id)
        notify << StreamRails.feed_manager.get_news_feeds(user.id)[:flat]
      end
    elsif self.likeable.try(:user)

      if self.likeable.user.id != self.user_id
        notify << StreamRails.feed_manager.get_notification_feed(self.likeable.user.id)
        notify << StreamRails.feed_manager.get_news_feeds(self.likeable.user.id)[:flat]
      end
    end

    notify
  end

  def activity_object
    self.likeable
  end

  def activity_verb
    self.likeable.class.to_s
  end

  private

    def add_points
      self.user.change_points( 'like', self.likeable_type )
    end

    def remove_points
      self.user.change_points( 'like', self.likeable_type, :destroy )
    end

    def remove_from_feed
      feed = StreamRails.feed_manager.get_user_feed(self.user_id)
      feed.remove_activity("Like:#{self.id}", foreign_id=true)
    end

    def trigger_likes_count
      case self.likeable_type
      when "Comment" || "Post" || "Video"
        self.likeable.update_attributes(likes_count: self.likeable.likes.count)
      end
    end
end
