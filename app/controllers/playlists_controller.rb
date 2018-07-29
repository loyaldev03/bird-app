class PlaylistsController < ApplicationController

  before_action :authenticate_user!, except: [:sync_playlist]
  before_action :set_notifications, only: [:show]

  def show
    @user = User.find params[:id]
    @playlists = current_user.playlists
  end

  def get
    @playlist = Playlist.find params[:playlist_id]
  end

  def load
    if current_user
      if current_user.current_playlist_id.present?
        if params[:playlist_id].present?
          playlist = Playlist.find params[:playlist_id]
          current_user.update_attributes(current_playlist_id: playlist.id)
        else
          playlist = current_user.current_playlist
        end
      else # initial load
        playlist = Playlist.create(
          user: current_user, 
          tracks: Track.last.id, 
          current_track: "0:0" )
        current_user.update_attributes(current_playlist_id: playlist.id)
      end
    else
      render json: { 
          tracks: [ track_as_json( TrackPresenter.new( Track.last, nil ) ) ] 
        }
      return
    end

    tracks = playlist.tracks.map do |_track|
      track = TrackPresenter.new(_track, current_user)
      track_as_json( track )
    end

    playlist_name_form = render_to_string( 
        partial: 'playlists/change_name', 
        locals: { playlist: playlist } )

    if playlist.current_track.present?
      current_track_data = playlist.current_track.split(':')
      current_track = { index: current_track_data[0].to_i, time: current_track_data[1].to_i }
    else
      current_track = { index: 0, time: 0 }
    end

    render json: { tracks: tracks,
                   current_track: current_track,
                   playlist_name_form: playlist_name_form }
  end

  def copy
    
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

    def track_as_json track
      { id: track.id,
        track_number: track.track_number,
        title: track.title, 
        artists: track.artists,
        mp3: track.stream_uri,
        release_id: track.release_id,
        waveform: track.waveform_image_uri }
    end
end
