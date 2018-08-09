class Playlist < ApplicationRecord
  belongs_to :user

  def tracks_count
    tracks.to_s.split(',').count
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
