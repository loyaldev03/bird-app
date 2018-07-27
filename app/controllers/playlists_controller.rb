class PlaylistsController < ApplicationController

  before_action :authenticate_user!, except: [:sync_playlist]
  before_action :set_notifications, only: [:show]

  def show
    @user = User.find params[:id]
    @playlists = current_user.playlists
  end

  def get_1
    @playlist = Playlist.find params[:playlist_id]
  end

  def get_playlist
    @playlist = Playlist.find params[:playlist_id]
    @current_track = params[:current_track] || 0
    current_user.update_attributes(current_playlist_id: @playlist.id)

    @tracks = []

    @playlist.tracks.each do |_track|
      track = TrackPresenter.new(_track, current_user)

      @tracks << { 
        release_id: track.release.id,
        track_number: track.track_number,
        id: track.id,
        title: track.title, 
        artists: track.artists, 
        mp3: track.stream_uri
      }
    end
  end

  def new
    @playlist = current_user.playlists.create
    current_user.update_attributes(current_playlist_id: @playlist.id )
  end

  def update
    @playlist = Playlist.find params[:id]

    if @playlist.user_id == current_user.id
      @playlist.update_attributes(playlist_params)
    end
  end

  def sync_playlist
    if current_user && current_user.current_playlist.present?
      current_user.current_playlist.update_attributes(
        tracks_ids: params[:tracks],
        current_track: "#{params[:current_track_id]}:#{params[:time] || 0}")
    end

    render json: {}
  end

  private

    def playlist_params
      params.require(:playlist).permit(:name)
    end
end
