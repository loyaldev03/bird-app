class Post < ApplicationRecord
  has_many :likes, as: :likeable
  has_many :reports, as: :reportable
  belongs_to :user
  belongs_to :topic

  belongs_to :parent,  class_name: "Post", optional: true
  has_many   :replies, class_name: "Post", foreign_key: :parent_id, dependent: :destroy

  has_many :feed_images, as: :feedable, dependent: :destroy
  accepts_nested_attributes_for :feed_images

  after_create :increment_count, :add_points
  after_destroy :decrement_count, :remove_points
  after_create_commit { CommentRelayJob.perform_later(self) }

  attr_accessor :post_hash

  scope :parents_posts, -> { where(parent_id: nil) }

  include AlgoliaSearch

  algoliasearch sanitize: true do
    attribute :text
  end

  include StreamRails::Activity
  as_activity

  def activity_notify
    notify = [StreamRails.feed_manager.get_feed( 'masterfeed', 1 ),
              StreamRails.feed_manager.get_feed('topic', self.topic_id)]

    if self.parent_id.present?
      unless self.user_id == self.parent.user_id
        notify << StreamRails.feed_manager.get_notification_feed(self.parent.user_id)
      end
      # notify << StreamRails.feed_manager.get_news_feeds(self.parent.user_id)[:flat]
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

end
