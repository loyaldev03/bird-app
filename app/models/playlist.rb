class Playlist < ApplicationRecord
  belongs_to :user

  def tracks_count
    tracks.to_s.split(',').count
  end

  def name
    super.present? ? super : "My playlist #{id}"
  end
end
