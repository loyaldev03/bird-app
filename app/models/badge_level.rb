class BadgeLevel < ApplicationRecord
  belongs_to :badge, inverse_of: :badge_levels
  belongs_to :user, inverse_of: :badge_levels

  include StreamRails::Activity
  as_activity

  def activity_notify
    [StreamRails.feed_manager.get_feed( 'masterfeed', 1 ),
     StreamRails.feed_manager.get_news_feeds(self.user_id)[:flat]]
  end

  def activity_object
    self.badge
  end

end
