class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  has_many :likes, as: :likeable
  has_many :reports, as: :reportable
  belongs_to :parent,  class_name: "Comment", optional: true
  has_many   :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  
  has_many :feed_images, as: :feedable, dependent: :destroy
  accepts_nested_attributes_for :feed_images

  after_create :add_to_feeds, :add_points, :increment_count
  after_destroy :decrement_count, :remove_points
  after_create_commit { CommentRelayJob.perform_later(self) if self.parent_id.present? }

  validates :user_id, presence: true

  attr_accessor :comment_hash

  include StreamRails::Activity
  # as_activity

  def activity_notify
    notify = [StreamRails.feed_manager.get_feed( 'masterfeed', 1 )]

    if self.commentable.try(:users)

      self.commentable.users.map do |user|
        unless self.user_id == user.id
          notify << StreamRails.feed_manager.get_notification_feed(user.id)
        end
      end

    elsif self.commentable.try(:user)

      unless self.user_id == self.commentable.user.id
        notify <<StreamRails.feed_manager.get_notification_feed(self.commentable.user.id)
      end

    end

    
    if self.parent_id.present?
      unless self.user_id == self.parent.user_id || self.parent.user.followed( self.commentable ).blank?
        notify << StreamRails.feed_manager.get_notification_feed(self.parent.user_id)
      end

    else

      unless self.commentable_type == "User" && self.commentable_id == self.user_id
        notify << StreamRails.feed_manager.get_feed( self.commentable_type.downcase, self.commentable_id )
      end

    end

    notify
  end

  def activity_should_sync?
    if (self.user.has_role?(:artist) || self.user.has_role?(:admin)) && 
        self.commentable_type == "User" && 
        self.commentable_id == self.user_id &&
        self.parent_id.present?
      false
    else
      true
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

    def add_to_feeds
      user_feed = StreamRails.feed_manager.get_user_feed( self.user_id )
      activity = {
        actor: "User:#{self.user_id}",
        verb: "Comment",
        object: "#{self.commentable_type}:#{self.commentable_id}",
        foreign_id: "Comment:#{self.id}",
        time: DateTime.now.iso8601
      }

      activity_notify.each do |feed| 
        logger.warn "FEED"
        logger.warn feed.inspect
        feed.add_activity(activity)
      end

      user_feed.add_activity(activity) if activity_should_sync?

      return if self.user_id == self.commentable_id && self.commentable_type == 'User'

      if self.user.followed( self.commentable ).blank?
        news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(self.user_id)[:aggregated]

        self.user.follows.create(followable_id: self.commentable_id, followable_type: self.commentable_type)
        news_aggregated_feed.follow(self.commentable_type.downcase, self.commentable_id)

        unless self.commentable_type == "User"
          feed_for_tab = StreamRails.feed_manager
              .get_feed("#{self.commentable_type.downcase}_user_feed", self.user_id)
          feed_for_tab.follow( self.commentable_type.downcase, self.commentable_id )
        end
      end
    end

end
