class Playlist < ApplicationRecord
  belongs_to :user
  has_many :likes, as: :likeable
  has_many :comments, as: :commentable

  def tracks_count
    tracks_ids.to_s.split(',').count
  end

  def tracks
    tracks_ids.to_s.split(',').map do |track_id|
      Track.find track_id
    end
  end

  def name
    super.present? ? super : "My playlist #{id}"
  end
end
