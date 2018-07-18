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
  after_update :update_braintree_customer
  before_destroy :cancel_braintree_subscription

  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
  after_update :crop_avatar
  
  attr_accessor :subscription
  enum gender: [:female, :male]

  validates :first_name, presence: true

  enum subscription_type: [:member, :vip, :admin]
  enum subscription_length: [:unknown, :monthly_old, :yearly_old, 
      :monthly_7, :monthly_10, :yearly_100]

  has_many :badge_levels, inverse_of: :user
  has_many :badges, through: :badge_levels
  has_many :badge_points

  has_many :reports

  has_many :topics
  has_many :posts
  has_many :comments
  has_many :commented, as: :commentable, class_name: 'Comment'
  has_many :videos
  accepts_nested_attributes_for :videos, :allow_destroy => true

  has_many :follows
  has_many :followed_users, through: :follows, source: :followable, source_type: "User"

  has_many :likes
  has_one :artist_info, foreign_key: "artist_id"
  accepts_nested_attributes_for :artist_info, :allow_destroy => true
  has_and_belongs_to_many :releases
  # has_many :announcements

  has_many :as_admin_announcements, foreign_key: "admin_id", class_name: "Announcement"
  has_many :as_admin_releases, foreign_key: "admin_id", class_name: "Release"

  has_many :tracks_users
  has_many :tracks, through: :tracks_users
  has_many :playlists
  has_many :downloads

  include AlgoliaSearch

  algoliasearch do
    attribute :first_name, :last_name
  end



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

  def releases_tracks
    releases = self.releases.published.ids
    Track.where("release_id IN (?)",releases)
  end

  def followers
    User.joins(:follows).where("follows.followable_id = ? AND follows.followable_type = 'User'", self.id)
  end

  def followed object
    self.follows.where(followable_id: object.id, followable_type: object.class.to_s).first
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

    return if has_role?(:admin) || has_role?(:artist)
    return unless cahced_active_subscription?
    
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
      leaderboard_kind = BadgeKind.find_by(ident: 'leaderboard_points')

      if leaderboard_kind.present?
        leaderboard_kind.badges.each do |badge|
          if self.points >= badge.points && !self.badges.include?(badge)
            self.badges << badge
          end
        end
      end

      membership_kind = BadgeKind.find_by(ident: 'membership_level')
      return unless membership_kind

      id_with_max_days = nil

      BadgeActionType.where(badge_kind_id: membership_kind.id).each do |action_type|
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

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email || "example#{SecureRandom.hex(10)}@mail.com"
      user.first_name = auth.info.first_name || "noname"
      user.last_name = auth.info.last_name
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


  # Braintree methods
  def braintree_customer
    # Find Customer form our cached db entry
    if braintree_customer_id
      begin
        return Braintree::Customer.find(braintree_customer_id)
      rescue Braintree::NotFoundError
        update(braintree_customer_id: nil)
      end
    end

    # Search Braintree for Customer
    search_results = Braintree::Customer.search do |search|
      search.email.is email
    end

    if search_results.any?
      update(braintree_customer_id: search_results.first.id)
      return Braintree::Customer.find(search_results.first.id)
    end

    nil
  end

  def update_braintree_customer
    # If these fields changed and user is a Braintree customer
    if (%w[first_name last_name email] & changes.keys).present? && braintree_customer
      # Update Braintree's records
      Braintree::Customer.update(
        braintree_customer.id,
        first_name: first_name,
        last_name: last_name,
        email: email
      )
    end
  end

  def braintree_subscription
    # Find Subscription from our cached db entry
    if braintree_subscription_id
      begin
        return Braintree::Subscription.find(braintree_subscription_id)
      rescue Braintree::NotFoundError
        update(braintree_subscription_id: nil)
      end
    end

    # Get First Subscription Customer has
    if braintree_customer
      subscriptions = braintree_customer.payment_methods.map(&:subscriptions).flatten.select { |s| s.status == 'Active' }

      if subscriptions.size > 1
        SLACK.ping "User #{id} has multiple active subscriptions!"
        # Honeybadger.notify("User #{id} has multiple active subscriptions!")
      end

      if subscriptions.any?
        update(braintree_subscription_id: subscriptions.first.id)
        return Braintree::Subscription.find(subscriptions.first.id)
      end
    end

    nil
  end

  def active_subscription?
    # VIPs and Admins are always active
    return true if subscription_type == 'vip' || subscription_type == 'admin'

    # Quick fail if subscription never started
    return false unless subscription_started_at

    # Check for active braintree subscription
    # TODO: this currently will always reach out to Braintree. This also is used in SubscribedController, so we should use cached values instead
    if braintree_subscription
      # If cache expiration time exists and is in the future
      if braintree_subscription_expires_at && Date.today <= braintree_subscription_expires_at
        return true
      end

      # Else refresh cache
      if braintree_subscription.trial_period
        update(braintree_subscription_expires_at: Date.parse(braintree_subscription.next_billing_date))
      else
        update(braintree_subscription_expires_at: (Date.parse(braintree_subscription.paid_through_date) + 1))
      end

      # And Check again
      if braintree_subscription_expires_at && Date.today <= braintree_subscription_expires_at
        return true
      end
    end

    # When all else fails, return false
    false
  end

  def cahced_active_subscription?
    return true if subscription_type == 'vip' || subscription_type == 'admin'
    true if braintree_subscription_expires_at && Date.today <= braintree_subscription_expires_at
  end

  def cancel_braintree_subscription
    Braintree::Subscription.cancel(braintree_subscription_id) if braintree_subscription
    update!(
      subscription_started_at: nil,
      braintree_customer_id: nil,
      braintree_subscription_id: nil,
      braintree_subscription_expires_at: nil
    )
  end


  def additional_info_set?
    [
      city,
      shipping_address,
      birthdate,
      t_shirt_size
    ].all?(&:present?)
  end

  def subscriber_type
    if braintree_subscription_expires_at && Date.today <= braintree_subscription_expires_at
      return "#{braintree_subscription.trial_period ? 'Trial ' : ''}Birdfeed #{subscription_length.split('_')[0].titleize}"
    end
    'CHIRP FREE'
  end


  def current_playlist
    Playlist.find_by_id current_playlist_id
  end


  def self.batch_follow_to_general_actions id=nil
    if id
        StreamRails.feed_manager.client
            .follow_many( User.intital_payload([User.find_by_id(id)]) )
    else
      find_in_batches(start: 0, batch_size: 200) do |group|
        StreamRails.feed_manager.client.follow_many( User.intital_payload(group) )
      end
    end

    User.with_role(:admin).each do |user|
      notify_feed = StreamRails.feed_manager.get_notification_feed( user.id )
      notify_feed.unfollow('release_create', '1')
      notify_feed.unfollow('announcement_create', '1')
    end

  end

  def follow_general_actions
    batch_follow_to_general_actions self.id
  end

  def self.intital_payload group
    payload = []
    group.each do |user|
      payload << { source: "notification:#{user.id}", target: 'release_create:1' }
      payload << { source: "notification:#{user.id}", target: 'announcement_create:1' }
      payload << { source: "timeline_aggregated:#{user.id}", target: 'release_create:1' }
      payload << { source: "timeline_aggregated:#{user.id}", target: 'announcement_create:1' }
      payload << { source: "release_user_feed:#{user.id}", target: 'release_create:1' }
      payload << { source: "announcement_user_feed:#{user.id}", target: 'announcement_create:1' }
      payload << { source: "timeline_aggregated:#{user.id}", target: "timeline:#{user.id}" }
      payload << { source: "user_aggregated:#{user.id}", target: "user:#{user.id}" }
    end

    payload
  end

  private

    def set_default_avatar
      self.avatar = primary_avatar(self.name) unless self.avatar.present?
    end

end
