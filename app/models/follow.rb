class Follow < ApplicationRecord
  belongs_to :user
  belongs_to :followable, polymorphic: true
  validates :user_id, :followable_id, :followable_type, presence: true

  after_create :add_points, :feed_masterfeed#, :feed_release_topic_announcement
  after_save :trigger_followers_count
  after_destroy :trigger_followers_count, :remove_points, :remove_from_aggregated_feed#, :unfeed_release_topic_announcement

  include StreamRails::Activity
  as_activity

  def activity_notify
    notify = [StreamRails.feed_manager.get_feed('user_aggregated', self.user_id)]
    if self.followable_type == 'User'
      notify << StreamRails.feed_manager.get_notification_feed(self.followable_id)
    end

    notify
  end

  def activity_object
    self.followable
  end

  def activity_verb
    self.followable.class.to_s
  end

  private

    def add_points
      self.user.change_points( 'follow', self.followable_type )
    end

    def remove_points
      self.user.change_points( 'follow', self.followable_type, :destroy )
    end

    # def feed_release_topic_announcement

    # end

    # def unfeed_release_topic_announcement

    # end

    def remove_from_aggregated_feed
      feed = StreamRails.feed_manager.get_feed('user_aggregated', self.user_id)
      feed.remove_activity("Follow:#{self.id}", foreign_id=true)
    end

    def feed_masterfeed
      feed = StreamRails.feed_manager.get_feed( 'masterfeed', 1 )
      activity = create_activity
      feed.add_activity(activity)
    end

    def trigger_followers_count
      if self.followable.class == User && self.followable.has_role?(:artist)
        artist_info = ArtistInfo.find_or_create_by(artist_id: self.followable.id)
        artist_info.update_attributes(followers_count: self.followable.followers.count )
      end
    end
end
