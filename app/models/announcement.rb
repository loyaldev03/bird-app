class Announcement < ApplicationRecord
  # belongs_to :user, optional: true
  belongs_to :admin, optional: true, foreign_key: "admin_id", class_name: "User"
  belongs_to :release, optional: true
  has_many :likes, as: :likeable
  has_many :comments, as: :commentable


  # after_save :change_published_date, only: :update


  mount_uploader :avatar, ReleaseUploader

  include StreamRails::Activity
  as_activity

  def followers
    User.joins(:follows).where("follows.followable_id = ? AND follows.followable_type = 'Announcement'", self.id)
  end

  def activity_notify
    [StreamRails.feed_manager.get_feed( 'general_actions', 1 ),
     StreamRails.feed_manager.get_feed( 'masterfeed', 1 )]
  end

  def activity_object
    self
  end

  def activity_verb
    "Release"
  end

  #because announcements shouldn't have a user
  def activity_actor
    self.admin || User.with_role(:admin).first
  end

  # def activity_time
    # published_at.iso8601
  # end

  private
  
    # def change_published_date
    #   if published_at_changed?
    #     feed = StreamRails.feed_manager.get_feed( 'general_actions', 1 )
    #     feed.remove_activity("Announcement:#{self.id}", foreign_id=true)

    #     activity = create_activity
        
    #     feed.add_activity(activity)
    #   end
    # end
end
