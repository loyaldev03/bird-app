class PlayerController < ApplicationController
  before_action :set_vars
  before_action :set_notifications, 
      only: [:liked_tracks, :recently_tracks, :downloaded_tracks]
  
  def liked_tracks
    @tracks = @user.liked_by_type('Track').map do |_track|
      TrackPresenter.new(_track, current_user)
    end
  end

  def recently_tracks
    @tracks = @user.recently_items.map do |item|
      TrackPresenter.new(item.track, current_user)
    end
  end

  def downloaded_tracks
    @tracks = @user.downloads.map { |d| TrackPresenter.new(d.track, current_user) }
  end

  private

    def set_vars
      @user = User.find params[:player_id]
      @playlists = @user.playlists
    end

end
