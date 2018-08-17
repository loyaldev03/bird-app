class PlayerController < ApplicationController
  before_action :set_notifications, only: [:liked_tracks]
  
  def liked_tracks
    @user = User.find params[:player_id]
    @tracks = @user.liked_by_type('Track').map do |_track|
      track_presenter = TrackPresenter.new(_track, current_user)
    end
    @playlists = @user.playlists
  end

end
