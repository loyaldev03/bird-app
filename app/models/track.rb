class Track < ApplicationRecord
  has_many :likes, as: :likeable
  has_many :comments, as: :commentable
  belongs_to :release
  has_many :tracks_users, dependent: :destroy
  has_many :users, through: :tracks_users
  has_many :track_files
  has_many :downloads
  has_many :recently_items
  belongs_to :track_info, optional: true
  accepts_nested_attributes_for :track_info, allow_destroy: true

  mount_uploader :uri, TrackUploader

  validates :track_number, :isrc_code, :title, presence: true

  ratyrate_rateable "main"

  include AlgoliaSearch

  algoliasearch do
    attribute :title, :genre, :isrc_code
  end

  after_save { ProcessingTrackJob.perform_later(self) }
  after_create :create_info

  def create_info
    TrackInfo.create(track: self) if track_info.nil?
  end

  def stream_uri(is_sample=true, browser)
    return sample_mp3_uri if is_sample && browser == 'Safari'
    return sample_ogg_uri if is_sample && browser != 'Safari'

    if browser == 'Safari'
      return  track_files.where(
                format: TrackFile.formats[:mp3], 
                encode_status: TrackFile.encode_statuses[:complete])
              .last
              .url_string
    else
      return  track_files.where(
                format: TrackFile.formats[:ogg], 
                encode_status: TrackFile.encode_statuses[:complete])
              .last
              .url_string
    end
  end

  def download_uris
    uris = track_files.empty? ? { 'WAV' => uri.url } : {}
    %w[mp3 aiff flac wav].each do |format|
      tf = track_files.find_by(format: TrackFile.formats[format])
      uris[format.split('_').first.upcase,] = tf.download_uri if tf
    end

    uris
  end

  def file_name
    "#{'%02i' % track_number}. #{artist} - #{title} - Dirtybird".gsub(/[^0-9A-Za-z.\(\)\-\  ]/, '')
  end

  def sample_file_name
    "#{'%02i' % track_number}. #{artist} - #{title} - Sample - Dirtybird".gsub(/[^0-9A-Za-z.\(\)\-\  ]/, '')
  end

  def user_allowed?(user)
    return false unless user
    return true if user.vip?
    return false unless release.published?
    return false unless user.subscription_started_at
    return false if user.subscription_length == 'monthly_insider'
    return false if user.subscription_length == 'yearly_insider'
    return true if release.available_to_all?
    return true if release.published_at >= user.subscription_started_at - 3.months
    false
  end

  def artists
    if artist_as_string && artist.present?
      artist
    elsif users.any?
      users.map(&:name).join(' & ')
    elsif artist.present?
      artist
    else
      'Various Artists'
    end
  end

  def avatar
    release.avatar
  end

  private

    def step_name
      "#{self.class.name}_#{id}"
    end

end
