class PlaylistsController < ApplicationController

  before_action :authenticate_user!, except: [:sync_playlist]

  def show
    playlist = Playlist.find params[:id]
    current_user.update_attributes(current_playlist_id: playlist.id)

    @playlist_id = playlist.id

    @tracks = []

    playlist.tracks.to_s.split(',').each do |track_id|
      track = TrackPresenter.new(Track.find( track_id ), current_user)

      if track.artist_as_string && track.artist.present?
        artists = track.artist
      elsif track.users.any?
        track.users.each do |u|
          artists = track.users.map(&:name).join(' & ')
        end
      elsif track.artist.present?
        artists = track.artist
      else
        artists = 'Various Artists'
      end

      @tracks << { 
        release_id: track.release.id,
        track_number: track.track_number,
        id: track.id,
        title: track.title, 
        artists: artists, 
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
        tracks: params[:tracks],
        current_track: "#{params[:current_track_id]}:#{params[:time] || 0}")
    end

    render json: {}
  end

  private

    def playlist_params
      params.require(:playlist).permit(:name)
    end
end
