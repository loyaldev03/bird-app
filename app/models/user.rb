class User < ApplicationRecord
  include HomeHelper

  mount_uploader :avatar, AvatarUploader

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:facebook, :google_oauth2]
  rolify
  ratyrate_rater

  before_create :set_default_avatar, only: :create
  after_create :follow_general_actions, only: :create

  attr_accessor :subscription
  enum gender: [:female, :male]

  validates :first_name, presence: true

  enum subscription_type: [:member, :vip, :admin]

  has_many :badge_levels, inverse_of: :user
  has_many :badges, through: :badge_levels
  has_many :badge_points

  has_many :topics
  has_many :posts
  has_many :comments
  has_many :commented, as: :commentable, class_name: 'Comment'
  has_many :videos

  has_many :follows
  has_many :followed_users, through: :follows, source: :followable, source_type: "User"

  has_many :likes
  has_one :artist_info, foreign_key: "artist_id"
  has_and_belongs_to_many :releases
  has_many :announcements
  has_many :tracks_users
  has_many :tracks, through: :tracks_users
  has_one :playlist
  has_many :downloads

  include AlgoliaSearch

  algoliasearch do
    attribute :first_name, :last_name
  end

  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
  after_update :crop_avatar

  def badges_by_kind kind
    badge_kind = BadgeKind.find_by(ident: kind)
    return unless badge_kind
    self.badges.where(badge_kind_id: badge_kind.id)
  end

  def crop_avatar
    avatar.recreate_versions! if crop_x.present?
  end

  def name
    "#{first_name} #{last_name}"
  end

  def online?
    begin
      $redis_onlines.exists( self.id )
    rescue Redis::CannotConnectError
      return false
    end
  end

  def vip?
    # Admins are also VIPs
    subscription_type == 'vip' || subscription_type == 'admin'
  end

  def admin?
    subscription_type == 'admin'
  end

  def active_subscription?
    return true if subscription_type == 'vip' || subscription_type == 'admin'

    return false unless subscription_started_at

    if braintree_subscription
      if braintree_subscription_expires_at && Date.today <= braintree_subscription_expires_at
        return true
      end
    end

    false
  end

  def releases_tracks
    releases = self.releases.published.ids
    Track.where("release_id IN (?)",releases)
  end

  def followers
    User.joins(:follows).where("follows.followable_id = ? AND follows.followable_type = 'User'", self.id)
  end

  def posts_from_followed_topics
    topic_ids = "SELECT followable_id FROM follows WHERE user_id = :user_id AND followable_type = 'Topic'"
    Post.where("topic_id IN (#{topic_ids})", user_id: self.id).order(created_at: :desc)
  end

  def already_liked object
    likes.where("likeable_id = ? AND likeable_type = ?", object.id, object.class.to_s).first
  end


  def change_points(income_action_type, action_model, destroy=nil)
    #points #TODO BadgePoint(badge_id) not needed
    kind_name = case action_model
    when "Comment"
      types = ["Release", "Track"]
      "music"
    when "Announcement"
      types = ["Release", "Track"]
      "music"
    when "Release"
      types = ["Release", "Track"]
      "music"
    when "Track"
      types = ["Release", "Track"]
      "music"
    when "Topic"
      types = ["Topic"]
      "forum"
    when "Post"
      types = ["Post"]
      "forum"
    when "User"
      types = ["User"]
      "community"
    end

    if income_action_type == 'member_over_time'
      badge_kind = BadgeKind.find_by(ident: 'Membership Level')
      return unless badge_kind

      max_days = 0
      id_with_max_days = nil

      BadgeActionType.where(badge_kind_id: badge_kind.id).each do |action_type|

        if max_days < action_type.count_to_achieve
          max_days = action_type.count_to_achieve
        end

        if action_type.count_to_achieve < (DateTime.now - self.created_at.to_datetime).to_i

          action_type.badges.each do |badge|
            unless self.badges.include?(badge)
              self.badges << badge 
              self.badge_levels.last.update_attributes(notified: true)
              id_with_max_days = self.badge_levels.last.id
            end
          end
        end
      end

      if id_with_max_days
        self.badge_levels.find(id_with_max_days).update_attributes(notified: false)
      end

    else

      kind = BadgeKind.where(ident: kind_name).first
      action_type = BadgeActionType.where(ident: income_action_type, badge_kind_id: kind.id).first
      points_for_type = self.badge_points.where(badge_action_type_id: action_type.id).last

      if points_for_type.blank?
        points_for_type = self.badge_points.create( 
              badge_kind_id: action_type.badge_kind_id,
              value: 0,
              accumulated_count: 0,
              accumulated_at: DateTime.now,
              badge_action_type_id: action_type.id )
      end

      if destroy == :destroy
        if points_for_type.accumulated_count = 0 && points_for_type.value > 0
          points_for_type.decrement! :value, action_type.points
          points_for_type.update_attributes( accumulated_count: action_type.count_to_achieve - 1 )
        elsif points_for_type.accumulated_count = 1 && points_for_type.value = 0
          points_for_type.decrement! :accumulated_count
          points_for_type.update_attributes( accumulated_at: nil )
        else
          points_for_type.decrement! :accumulated_count
        end
      else
        points_for_type.increment! :accumulated_count

        if points_for_type.accumulated_at.blank?
          points_for_type.update_attributes( accumulated_at: DateTime.now )
        end

        if points_for_type.accumulated_count >= action_type.count_to_achieve
          points_for_type.increment! :value, action_type.points if action_type.points
          points_for_type.update_attributes( accumulated_count: 0, accumulated_at: DateTime.now )
        end
      end

      #badges
      weights = "SELECT badge_id FROM badge_points_weights LEFT JOIN badge_action_types ON badge_action_types.id = badge_points_weights.badge_action_type_id WHERE badge_action_type_id = :action_type_id AND badge_action_types.badge_kind_id = :kind_id"
      badges = Badge.where("id IN (#{weights})", action_type_id: action_type.id, kind_id: kind.id)

      user_badges = self.badges.pluck(:id)

      badges.reject { |b| user_badges.include?(b.id) if user_badges.present? }.each do |badge|

        next unless badge.badge_kind_id == kind.id

        related_badges_should_be = badge.depended_badges.pluck(:id)

        if related_badges_should_be.all? { |i| user_badges.include?(i) }
          # last_related_badge = "(SELECT MAX(created_at) FROM badge_levels WHERE user_id = :user_id AND badge_id IN (:badge_id))"
          # related_badges_user_have = related_badges_should_be & user_badges
        else
          next
        end
        # else
          # last_related_badge = "(SELECT created_at FROM users WHERE id = :user_id)"
        # end

        # weight = BadgePointsWeight.joins(:badge_action_type)
        #     .where('badge_action_types.name = ? AND badge_id = ?', 
        #         income_action_type, badge.id).first
        # next unless weight.active?

        roles = BadgePointsWeight.joins(:badge_action_type)
              .where('badge_action_types.name LIKE ? AND badge_id = ? AND active = true', 'role%', badge.id)

        if roles.present? && roles.count == 1 
          role = roles[0].badge_action_type.name.split[1]
          next unless self.has_role? role
        end

        actions_left = self.actions_left_for_badge(badge)

        if actions_left.count == 0
          self.badges << badge

          #TODO rewrite for badges from other kinds
          self.badge_points
                .where(badge_kind_id: badge.badge_kind_id)
                .update_all(accumulated_count: 0, accumulated_at: DateTime.now)
        end
      end
    end
  end

  def actions_left_for_badge badge
    actions_should_be = badge.badge_action_types
            .joins(:badge_points_weights)
            .where("badge_points_weights.active = true AND name NOT LIKE 'role%'")

    actions_left = []

    actions_should_be.each do |action|
      points_for_action = self.badge_points.where(badge_action_type_id: action.id).first

      if points_for_action.present?

        last_related_badge_date = badge.depended_badges.joins(:badge_levels).maximum("badge_levels.created_at")

        if badge.depended_badges.count == 0

          if points_for_action.value == 0
            actions_left << action
          end

        else 

          if points_for_action.value == 0
            actions_left << action
          else

            if points_for_action.accumulated_at >= last_related_badge_date
              actions_left << action
            end

          end
        end

      else

        actions_left << action

      end
    end

    actions_left
  end

  def next_badges
    user_badges = self.badges.pluck(:id)
    badges = []
    
    Badge.all.reject { |b| user_badges.include?(b.id) if user_badges.present? }.each do |badge|
      related_badges_should_be = badge.depended_badges.pluck(:id)

      if related_badges_should_be.all? { |i| user_badges.include?(i) }
        badges << badge
      end
    end

    badges = badges.group_by(&:badge_kind_id)

    persents = {}

    badges.each do |id, badges_by_kind|
      last_badge = badges_by_kind.sort_by{|b| b.created_at}.first
      actions_should_be = last_badge.badge_action_types
              .joins(:badge_points_weights)
              .where("badge_points_weights.active = true AND name NOT LIKE 'role%'")

      if actions_should_be.count == 0
        next
      elsif actions_should_be.count == 1
        type = actions_should_be.first
        points = self.badge_points.where(badge_action_type_id: type.id).first

        if points
          persents[id] = 
              ((points.accumulated_count.to_f / type.count_to_achieve)*100).round
        end
      else
        persents[id] = 
              (100.0 - (actions_left_for_badge(last_badge).count.to_f / 
              actions_should_be.count)*100).round
      end
    end

    persents
  end

  def followed(object = nil)
    self.follows.where(followable_id: object.id, followable_type: object.class.to_s).first
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      if auth.info.email
        user.email = auth.info.email
        user.name = auth.info.email.split('@')[0]
      else
        user.email = "example@mail.com"
        user.name = "noname"
      end
      user.password = Devise.friendly_token[0,20]
      #user.social_profile_picture = auth.info.image # assuming the user model has an image
    end
  end

  def points kind_id=nil
    if kind_id
      badge_points.where(badge_kind_id: kind_id).sum(:value)
    else
      badge_points.sum(:value)
    end
  end

  def self.batch_follow_to_general_actions offset=0
    users = all.offset(offset).limit(2500)
    users = users.map do |user|
      { source: "notification:#{user.id}", target: 'general_actions:1' }
    end

    StreamRails.feed_manager.client.follow_many(users)
  end

  private

    def set_default_avatar
      self.avatar = primary_avatar(self.name)
    end

    def follow_general_actions
      notification_feed = StreamRails.feed_manager.get_notification_feed(self.id)
      news_feed = StreamRails.feed_manager.get_news_feeds(self.id)[:flat]
      notification_feed.follow('general_actions', 1)
      news_feed.follow('general_actions', 1)
    end
end
