class Topic < ApplicationRecord
  belongs_to :user
  belongs_to :category, foreign_key: 'category_id', 
             class_name: "TopicCategory", optional: true
  has_many :likes, as: :likeable
  has_many :posts

  validates :user_id, :category_id, :title, :text, presence: true

  after_create :autofollow

  include AlgoliaSearch

  algoliasearch sanitize: true do
    attribute :title, :text
  end

  include StreamRails::Activity
  as_activity

  def activity_notify
    [StreamRails.feed_manager.get_feed( 'masterfeed', 1 )]
  end

  def activity_object
    self
  end

  private

    def autofollow
      if self.user.followed( self ).blank?
        news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(self.user_id)[:aggregated]
        notify_feed = StreamRails.feed_manager.get_notification_feed(self.user_id)

        self.user.follows.create(followable_id: self.id, followable_type: self.class.to_s)
        
        news_aggregated_feed.follow(self.class.to_s.downcase, self.id)
        notify_feed.follow(self.class.to_s.downcase, self.id)
      end
    end

end
