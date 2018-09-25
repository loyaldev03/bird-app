class Post < ApplicationRecord
  has_many :likes, as: :likeable
  has_many :comments, as: :commentable
  has_many :reports, as: :reportable
  belongs_to :user
  belongs_to :topic

  # belongs_to :parent,  class_name: "Post", optional: true
  # has_many   :replies, class_name: "Post", foreign_key: :parent_id, dependent: :destroy

  has_many :feed_images, as: :feedable, dependent: :destroy
  accepts_nested_attributes_for :feed_images

  after_create :add_points, :autofollow_topic
  after_destroy :remove_points
  after_create_commit { PostRelayJob.perform_later(self) }

  include AlgoliaSearch

  algoliasearch sanitize: true do
    attribute :body
  end

  include StreamRails::Activity
  as_activity

  def activity_notify
    notify = [StreamRails.feed_manager.get_feed( 'masterfeed', 1 ),
              StreamRails.feed_manager.get_feed('topic', topic_id)]

    if parent_id.present?
      unless user_id == parent.user_id || user.followed( topic ).blank?
        notify << StreamRails.feed_manager.get_notification_feed(parent.user_id)
      end
    end

    notify
  end

  def activity_object
    topic
  end

  def activity_verb
    "Topic"
  end

  def parents_comments
    Comment.where(parent_id: nil, 
                  commentable_type: "Post", 
                  commentable_id: id)
           .order(created_at: :asc)
  end

  private

    def add_points
      user.change_points( 'make post', "Post" )
    end

    def remove_points
      user.change_points( 'make post', "Post", :destroy )
    end

    def autofollow_topic
      if user.followed( topic ).blank?
        news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(user_id)[:aggregated]

        user.follows.create(followable_id: topic_id, followable_type: "Topic")
        news_aggregated_feed.follow('topic', topic_id)

        feed_for_tab = StreamRails.feed_manager
            .get_feed("topic_user_feed", user_id)
        feed_for_tab.follow( 'topic', topic_id )
      end
    end

end
