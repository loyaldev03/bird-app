class Post < ApplicationRecord
  has_many :likes, as: :likeable
  has_many :reports, as: :reportable
  belongs_to :user
  belongs_to :topic

  belongs_to :parent,  class_name: "Post", optional: true
  has_many   :replies, class_name: "Post", foreign_key: :parent_id, dependent: :destroy

  has_many :feed_images, as: :feedable, dependent: :destroy
  accepts_nested_attributes_for :feed_images

  after_create :increment_count, :add_points, :autofollow_topic
  after_destroy :decrement_count, :remove_points
  after_create_commit { CommentRelayJob.perform_later(self) }

  attr_accessor :post_hash

  scope :parents_posts, -> { where(parent_id: nil) }

  include AlgoliaSearch

  algoliasearch sanitize: true do
    attribute :body
  end

  include StreamRails::Activity
  as_activity

  def activity_notify
    notify = [StreamRails.feed_manager.get_feed( 'masterfeed', 1 ),
              StreamRails.feed_manager.get_feed('topic', self.topic_id)]

    if self.parent_id.present?
      unless self.user_id == self.parent.user_id || self.user.followed( self.topic ).blank?
        notify << StreamRails.feed_manager.get_notification_feed(self.parent.user_id)
      end
    end

    notify
  end

  def activity_object
    self.topic
  end

  def activity_verb
    "Topic"
  end

  private

    def add_points
      self.user.change_points( 'make post', "Post" )
    end

    def remove_points
      self.user.change_points( 'make post', "Post", :destroy )
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

    def autofollow_topic
      if self.user.followed( self.topic ).blank?
        news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(self.user_id)[:aggregated]

        self.user.follows.create(followable_id: self.topic_id, followable_type: "Topic")
        news_aggregated_feed.follow('topic', self.topic_id)

        feed_for_tab = StreamRails.feed_manager
            .get_feed("topic_user_feed", self.user_id)
        feed_for_tab.follow( 'topic', self.topic_id )
      end
    end

end
