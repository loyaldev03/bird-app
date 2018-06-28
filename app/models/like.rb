class Like < ApplicationRecord
  belongs_to :user
  belongs_to :likeable, polymorphic: true
  
  after_create :add_points, :feed_masterfeed, :trigger_likes_count
  after_destroy :trigger_likes_count, :remove_points, :remove_from_aggregated_feed

  
  include StreamRails::Activity
  as_activity

  def activity_notify
    notify = [StreamRails.feed_manager.get_feed('user_aggregated', self.user_id)]

    if self.likeable.try(:users)
      self.likeable.users.each do |user|
        notify.merge StreamRails.feed_manager.get_notification_feed(user.id)
      end
    elsif self.likeable.try(:user)
      notify << StreamRails.feed_manager.get_notification_feed(self.likeable.user.id)
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

    def remove_from_aggregated_feed
      feed = StreamRails.feed_manager.get_feed('user_aggregated', self.user_id)
      feed.remove_activity("Like:#{self.id}", foreign_id=true)
    end

    def feed_masterfeed
      feed = StreamRails.feed_manager.get_feed( 'masterfeed', 1 )
      activity = create_activity
      feed.add_activity(activity)
    end

    def trigger_likes_count
      case self.likeable_type
      when "Comment" || "Video"
        self.likeable.update_attributes(likes_count: self.likeable.likes.count)
      end
    end
end
