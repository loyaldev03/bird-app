class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  has_many :likes, as: :likeable
  belongs_to :parent,  class_name: "Comment", optional: true
  has_many   :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  
  has_many :feed_images, as: :feedable, dependent: :destroy
  accepts_nested_attributes_for :feed_images

  before_create :autofollow_commentable_feed
  after_create :add_points, :feed_commentable, :increment_count
  after_destroy :decrement_count, :remove_points

  validates :user_id, :body, presence: true

  attr_accessor :comment_hash

  include StreamRails::Activity
  as_activity

  def activity_notify
    notify = [StreamRails.feed_manager.get_feed( 'masterfeed', 1 )]

    if self.commentable.try(:users)
      self.commentable.users.map do |user|
        notify << StreamRails.feed_manager.get_notification_feed(user.id)
      end

    elsif self.commentable.try(:user)
      notify <<StreamRails.feed_manager.get_notification_feed(self.commentable.user.id)
    elsif self.commentable_type == "User"
      notify << StreamRails.feed_manager.get_notification_feed(self.commentable_id)
    end

    if self.parent_id.present?
      notify << StreamRails.feed_manager.get_notification_feed(self.commentable.user.id)
      notify << StreamRails.feed_manager.get_news_feeds(self.commentable.user.id)[:aggregated]
    end

    notify
  end

  def activity_object
    self.commentable
  end

  # def activity_extra_data
  #   {'parent_id' => self.parent_id}
  # end

  def activity_should_sync?
    if (self.user.has_role?(:artist) || self.user.has_role?(:admin)) && 
        self.commentable_type == "User" && 
        self.commentable_id == self.user_id
      true
    else
      false
    end
  end

  private

    def add_points
      self.user.change_points( 'comment', self.commentable_type )
    end

    def remove_points
      self.user.change_points( 'comment', self.commentable_type, :destroy )
    end

    def increment_count
      self_parent = parent

      while self_parent.present?
        self_parent.increment! :replies_count
        self_parent = self_parent.parent
      end
    end

    def decrement_count
      self_parent = parent

      while self_parent.present?
        self_parent.decrement! :replies_count
        self_parent = self_parent.parent
      end
    end

    def autofollow_commentable_feed
      if self.user_id != self.commentable_id && 
          self.commentable_type != 'User' &&
          self.user.followed( self.commentable ).blank?
        # user_feed = StreamRails.feed_manager.get_user_feed(self.user_id)
        notify_feed = StreamRails.feed_manager.get_notification_feed( self.user_id)
        news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(self.user_id)[:aggregated]

        self.user.follows.create(followable_id: self.commentable_id, followable_type: self.commentable_type)
        # user_feed.follow(self.commentable_type.downcase, self.commentable_id)
        notify_feed.follow(self.commentable_type.downcase, self.commentable_id)
        news_aggregated_feed.follow(self.commentable_type.downcase, self.commentable_id)
      end
    end

    def feed_commentable
      return if self.parent_id.present?

      feed = StreamRails.feed_manager.get_feed( self.commentable_type.downcase, self.commentable_id )
      activity = create_activity
      feed.add_activity(activity)
    end

    def feed_masterfeed
      feed = StreamRails.feed_manager.get_feed( 'masterfeed', 1 )
      activity = create_activity
      feed.add_activity(activity)
    end
end
