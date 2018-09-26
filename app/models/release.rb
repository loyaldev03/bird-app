class Release < ApplicationRecord
  has_many :likes, as: :likeable
  has_many :comments, as: :commentable
  has_many :tracks
  has_many :announcements
  has_many :track_files, through: :tracks
  has_many :release_files
  has_many :downloads, through: :tracks

  enum encode_status: [:pending, :complete, :failed] # can be nil # TODO: remove this
  enum release_type: [:usual, :exclusive, :d_select, :birdhouse]

  has_and_belongs_to_many :users
  belongs_to :admin, optional: true, foreign_key: "admin_id", class_name: "User"

  # after_create :add_to_general_feed
  after_update :change_published_date
  after_destroy :remove_from_general_feed

  accepts_nested_attributes_for :tracks, :allow_destroy => true

  validates :title, :release_date, :published_at, :catalog, presence: true

  mount_uploader :avatar, ReleaseUploader

  ratyrate_rateable "main"

  include AlgoliaSearch

  include StreamRails::Activity
  # as_activity

  algoliasearch sanitize: true do
    attribute :title, :catalog, :upc_code, :text
    # tags [self.published? ? 'published' : 'unpublished']
  end

  scope :published, -> { where("published_at < ?", DateTime.now).order(release_date: :desc) }

  def user_allowed?(user)
    return false unless user
    return true if user.vip?
    return false unless published?
    return false unless user.subscription_started_at
    return false if user.subscription_length == 'monthly_insider'
    return false if user.subscription_length == 'yearly_insider'
    return true if available_to_all?
    return true if published_at >= user.subscription_started_at - 3.months
    false
  end

  def published?
    !published_at.nil? && published_at <= DateTime.now
  end

  def release_day
    release_date.strftime('%Y-%m-%d')
  end

  def release_year
    release_date.strftime('%Y')
  end

  def step_name
    "#{self.class.name}_#{id}"
  end

  def file_name
    "#{title} - #{artist} - Dirtybird".gsub(/[^0-9A-Za-z.\-\  ]/, '')
  end

  def download_uris
    return {} if release_files.empty?

    uris = {}

    %w[mp3 aiff flac wav].each do |format|
      rf = release_files.find_by(format: ReleaseFile.formats[format])
      uris[format.upcase] = rf.download_uri if rf
    end

    uris
  end

  def artists limit=nil
    if artist_as_string && artist.present?
      artist
    elsif users.any?
      artists = users.map(&:name)
      artists_count = artists.count

      if limit && artists_count > limit
        artists = artists[0..limit-1]
        artists = artists.map(&:strip).join(', ')
        artists += " & #{artists_count-limit} #{'other'.pluralize(artists_count-limit)}"
      else
        artists = artists.join(' & ')
      end
    elsif artist.present?
      artist
    else
      'Various Artists'
    end
  end

  private

    def add_to_general_feed
      release_create_feed = StreamRails.feed_manager.get_feed( 'release_create', 1 )
      masterfeed = StreamRails.feed_manager.get_feed( 'masterfeed', 1 )

      activity = {
        actor: "User:#{User.with_role(:admin).first.id}",
        verb: "Release",
        object: "Release:#{self.id}",
        foreign_id: "Release:#{self.id}",
        time: published_at.iso8601
      }

      self.users.each do |user|
        user_feed = StreamRails.feed_manager.get_user_feed( user.id )
        user_feed.add_activity(activity)
      end

      release_create_feed.add_activity(activity)
      masterfeed.add_activity(activity)
    end

    def remove_from_general_feed
      feed = StreamRails.feed_manager.get_feed( 'release_create', 1 )
      feed.remove_activity("Release:#{self.id}", foreign_id=true)
    end

    def change_published_date
      if saved_change_to_published_at?
        feed = StreamRails.feed_manager.get_feed( 'release_create', 1 )
        feed.remove_activity("Release:#{self.id}", foreign_id=true)

        self.users.each do |user|
          user_feed = StreamRails.feed_manager.get_user_feed( user.id )
          user_feed.remove_activity("Release:#{self.id}", foreign_id=true)
        end

        activity = {
          actor: "User:#{User.with_role(:admin).first.id}",
          verb: "Release",
          object: "Release:#{self.id}",
          foreign_id: "Release:#{self.id}",
          time: published_at.iso8601
        }

        feed.add_activity(activity)
      end
    end
end
