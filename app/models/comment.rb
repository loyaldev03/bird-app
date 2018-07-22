class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  has_many :likes, as: :likeable
  has_many :reports, as: :reportable
  has_many :comments, as: :commentable
  belongs_to :parent,  class_name: "Comment", optional: true
  has_many   :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  
  has_many :feed_images, as: :feedable, dependent: :destroy
  accepts_nested_attributes_for :feed_images

  after_create :add_to_feeds, :add_points, :increment_count
  after_destroy :decrement_count, :remove_points
  after_create_commit :comment_relay_job

  validates :user_id, presence: true

  attr_accessor :comment_hash

  include StreamRails::Activity
  # as_activity

  def activity_notify
    notify = [StreamRails.feed_manager.get_feed( 'masterfeed', 1 )]

    # for releases & announcements
    if commentable.try(:users)

      commentable.users.map do |user|
        unless user_id == user.id
          notify << StreamRails.feed_manager.get_notification_feed(user.id)
        end
      end

    elsif commentable.try(:user)

      unless user_id == commentable.user.id
        notify <<StreamRails.feed_manager.get_notification_feed(commentable.user.id)
      end

    end

    if parent_id.present?
      
      unless user_id == parent.user_id
        notify << StreamRails.feed_manager.get_notification_feed(parent.user_id)
      end

    end

    notify
  end

  def parents_comments
    Comment.where(parent_id: nil, 
                  commentable_type: "Comment", 
                  commentable_id: id)
           .order(created_at: :asc)
  end

  private

    def add_points
      user.change_points( 'comment', commentable_type )
    end

    def remove_points
      user.change_points( 'comment', commentable_type, :destroy )
    end

    def increment_count
      if %w(Comment Post).include? commentable_type
        commentable.increment! :replies_count
      end

      self_parent = parent

      while self_parent.present?
        self_parent.increment! :replies_count
        self_parent = self_parent.parent
      end
    end

    def decrement_count
      if %w(Comment Post).include? commentable_type
        commentable.decrement! :replies_count
      end

      self_parent = parent

      while self_parent.present?
        self_parent.decrement! :replies_count
        self_parent = self_parent.parent
      end
    end

    def comment_relay_job
      unless %w(User Release Announcement).include? commentable_type
        CommentRelayJob.perform_later(self)
      end
    end

    def add_to_feeds
      user_feed = StreamRails.feed_manager.get_user_feed( user_id )
      activity = {
        actor: "User:#{user_id}",
        verb: "Comment",
        object: "#{commentable_type}:#{commentable_id}",
        foreign_id: "Comment:#{id}",
        time: DateTime.now.iso8601
      }

      activity_notify.each do |feed|
        feed.add_activity(activity)
      end

      if %w(User Release Announcement).include? commentable_type
        user_feed.add_activity(activity)
        # StreamRails.feed_manager
        #     .get_feed( commentable_type.downcase, commentable_id )
        #     .add_activity(activity)
      end

      # autofollow
      return if user_id == commentable_id && commentable_type == 'User'
      return if user_id == commentable.try(:user_id)

      if user.followed( commentable ).blank?
        news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(user_id)[:aggregated]

        if %w(User Release Announcement).include? commentable_type
          user.follows.create(followable_id: commentable_id, followable_type: commentable_type)
          news_aggregated_feed.follow(commentable_type.downcase, commentable_id)
        end

        if commentable_type == 'Post'
          feed_for_tab = StreamRails.feed_manager
              .get_feed("topic_user_feed", user_id)
          feed_for_tab.follow( "topic", commentable.topic_id )
        end

        if %w(Release Announcement).include? commentable_type
          feed_for_tab = StreamRails.feed_manager
              .get_feed("#{commentable_type.downcase}_user_feed", user_id)
          feed_for_tab.follow( commentable_type.downcase, commentable_id )
        end
      end
    end

end
