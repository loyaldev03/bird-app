class Post < ApplicationRecord
  has_many :likes, as: :likeable
  belongs_to :user
  belongs_to :topic

  belongs_to :parent,  class_name: "Post", optional: true
  has_many   :replies, class_name: "Post", foreign_key: :parent_id, dependent: :destroy

  has_many :feed_images, as: :feedable, dependent: :destroy
  accepts_nested_attributes_for :feed_images

  after_create :feed_masterfeed, :feed_topic, :increment_count, :add_points
  after_destroy :decrement_count, :remove_points

  attr_accessor :post_hash

  scope :parents_posts, -> { where(parent_id: nil) }

  include AlgoliaSearch

  algoliasearch sanitize: true do
    attribute :text
  end

  include StreamRails::Activity
  as_activity

  # def activity_notify
  #   if self.commentable.try(:users)
  #     self.commentable.users.map do |user|
  #       StreamRails.feed_manager.get_notification_feed(user.id)
  #     end
  #   elsif self.commentable.try(:user)
  #     [StreamRails.feed_manager.get_notification_feed(self.commentable.user.id)]
  #   else
      
  #   end
  # end

  def activity_object
    self
  end

  def activity_target
    self.topic
  end

  def activity_verb
    "Comment"
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

    def feed_masterfeed
      feed = StreamRails.feed_manager.get_feed( 'masterfeed', 1 )
      activity = create_activity
      feed.add_activity(activity)
    end

    def feed_topic
      feed = StreamRails.feed_manager.get_feed( 'topic', self.topic_id )
      activity = create_activity
      feed.add_activity(activity)
    end

end
