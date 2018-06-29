class BadgeLevel < ApplicationRecord
  belongs_to :badge, inverse_of: :badge_levels
  belongs_to :user, inverse_of: :badge_levels

  include StreamRails::Activity
  as_activity

  def activity_notify
    [StreamRails.feed_manager.get_feed('user_aggregated', self.user_id)]
  end

  def activity_object
    self.badge
  end

end
