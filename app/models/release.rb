class Release < ApplicationRecord
  has_many :likes, as: :likeable
  has_many :comments, as: :commentable
  has_many :tracks
  has_many :announcements
  has_many :track_files, through: :tracks
  has_many :release_files
  has_many :downloads, through: :tracks

  enum encode_status: [:pending, :complete, :failed] # can be nil # TODO: remove this
  enum release_type: [:usual, :exclusive, :d_select]

  has_and_belongs_to_many :users
  belongs_to :admin, optional: true, foreign_key: "admin_id", class_name: "User"

  after_create :add_to_general_feed
  after_update :change_published_date
  after_destroy :remove_from_general_feed

  accepts_nested_attributes_for :tracks, :allow_destroy => true

  validates :title, :release_date, :published_at, presence: true

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
    return false if user.subscription_length == 'monthly_7'
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

    %w[mp3_320 aiff flac wav].each do |format|
      rf = release_files.find_by(format: ReleaseFile.formats[format])
      uris[format.split('_').first.upcase,] = rf.download_uri if rf
    end

    uris
  end

  def encode
    pending!
    steps = []
    formats = [:wav, :aiff, :flac, :mp3_160, :mp3_320]

    # Remove any existing TrackFiles and ReleaseFiles
    track_files.each(&:destroy)
    release_files.each(&:destroy)

    # Set up Track Encoding
    tracks.each do |track|
      steps.concat track.encode_steps(formats, nil)
    end

    # Set up ZIP File Creation
    zip_steps = encode_zip_steps(steps)
    steps.concat zip_steps

    # Submit Job to Transloadit
    TRANSLOADIT.assembly(
      steps: steps,
      notify_url: "#{ENV['BASE_URL']}/callbacks/transloadit"
    ).create!
  end

  def encode_zip_steps(all_steps)
    raise 'You must pass in all_steps so we can find common tracks to zip' unless all_steps

    steps = []

    # Generate Steps from TrackFile encode jobs
    all_steps.select { |step|
      step.name.match(/^TrackFile_\d+$/) # Only steps that look like TrackFiles
    }.group_by { |step| # Group By Format
      TrackFile.find(step.name.split(/_/)[1]).format # Group By TrackFile format
    }.each do |group_format, track_steps|
      # create ReleaseFile
      release_file = ReleaseFile.create(
        release: self,
        format: group_format,
        encode_status: :pending
      )
      steps.concat release_file.encode_steps(track_steps)
    end

    zip_export_step = TRANSLOADIT.step(
      "#{step_name}_export",
      '/s3/store',
      key: ENV['S3_KEY'],
      secret: ENV['S3_SECRET'],
      bucket_region: ENV['S3_REGION'],
      bucket: ENV['S3_BUCKET_NAME'],
      path: "releases/${unique_prefix}/#{file_name}.${file.ext}"
    )

    zip_export_step.use(steps)
    steps.push(zip_export_step)

    steps
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

      release_create_feed.add_activity(activity)
      masterfeed.add_activity(activity)
    end

    def remove_from_general_feed
      feed = StreamRails.feed_manager.get_feed( 'release_create', 1 )
      feed.remove_activity("Release:#{self.id}", foreign_id=true)
    end

    def change_published_date
      if published_at_changed?
        feed = StreamRails.feed_manager.get_feed( 'release_create', 1 )
        feed.remove_activity("Release:#{self.id}", foreign_id=true)

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
