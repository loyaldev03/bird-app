class Topic < ApplicationRecord
  belongs_to :user
  belongs_to :category, foreign_key: 'category_id', 
             class_name: "TopicCategory", optional: true
  has_many :likes, as: :likeable
  has_many :posts

  validates :user_id, :category_id, :title, :text, presence: true

  include AlgoliaSearch

  algoliasearch sanitize: true do
    attribute :title, :text
  end

  include StreamRails::Activity
  as_activity

  def activity_notify
    [StreamRails.feed_manager.get_feed('user_aggregated', self.user_id)]
  end

  def activity_object
    self
  end

end
