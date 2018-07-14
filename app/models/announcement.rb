class Announcement < ApplicationRecord
  # belongs_to :user, optional: true
  belongs_to :admin, optional: true, foreign_key: "admin_id", class_name: "User"
  belongs_to :release, optional: true
  has_many :likes, as: :likeable
  has_many :comments, as: :commentable


  # after_save :change_published_date, only: :update
  after_create :add_to_general_feed
  after_destroy :remove_from_general_feed

  mount_uploader :avatar, ReleaseUploader

  include StreamRails::Activity
  # as_activity

  def followers
    User.joins(:follows).where("follows.followable_id = ? AND follows.followable_type = 'Announcement'", self.id)
  end

  private

    def add_to_general_feed
      announcement_create_feed = StreamRails.feed_manager.get_feed( 'announcement_create', 1 )
      masterfeed = StreamRails.feed_manager.get_feed( 'masterfeed', 1 )

      activity = {
        actor: "User:#{User.with_role(:admin).first.id}",
        verb: "Release",
        object: "Announcement:#{self.id}",
        foreign_id: "Announcement:#{self.id}",
        time: DateTime.now.iso8601
      }

      announcement_create_feed.add_activity(activity)
      masterfeed.add_activity(activity)
    end

    def remove_from_general_feed
      feed = StreamRails.feed_manager.get_feed( 'announcement_create', 1 )
      feed.remove_activity("Announcement:#{self.id}", foreign_id=true)
    end
  
    # def change_published_date
    #   if published_at_changed?
    #     feed = StreamRails.feed_manager.get_feed( 'general_actions', 1 )
    #     feed.remove_activity("Announcement:#{self.id}", foreign_id=true)

    #     activity = create_activity
        
    #     feed.add_activity(activity)
    #   end
    # end
end
