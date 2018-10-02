class PlaylistsController < ApplicationController

  before_action :authenticate_user!, except: [:sync_playlist, :load]
  before_action :set_notifications, only: [:index, :show]

  def index
    @user = User.find params[:user_id]
    @playlists = @user.playlists
  end

  def show
    @playlist = Playlist.find params[:id]
    @user = @playlist.user
    @playlists = @user.playlists
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
          tracks_ids: Track.last.id, 
          current_track: "0:0" )
        current_user.update_attributes(current_playlist_id: playlist.id)
      end
    else
      track = Release.published.first.tracks.first
      render json: { 
          tracks: [ track_as_json( TrackPresenter.new( track, nil, @browser ) ) ] 
        }
      return
    end

    tracks = playlist.tracks.map do |_track|
      return nil unless _track.release
      track = TrackPresenter.new(_track, current_user, @browser)
      track_as_json( track )
    end

    tracks.compact!

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
                   playlist_name_form: playlist_name_form,
                   playlist_id: playlist.id }
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
      playlist = current_user.current_playlist

      if params[:add_tracks_ids].present?
        params[:add_tracks_ids].each do |id|
          playlist.tracks_ids = playlist.tracks_ids
                                        .to_s
                                        .split(',')
                                        .push(id)
                                        .join(',')
        end
      end

      if params[:delete_by_indices].present?
        params[:delete_by_indices].each do |i|
          tracks_ids = playlist.tracks_ids.to_s.split(',')
          tracks_ids.delete_at(i.to_i)
          playlist.tracks_ids = tracks_ids.join(',')
        end
      end

      if params[:current_track].present?
        playlist.current_track = "#{params[:current_track]}:#{params[:time] || 0}"
      end
      
      playlist.save
    end

    render json: {}
  end

  private

    def playlist_params
      params.require(:playlist).permit(:name)
    end

    def track_as_json track
      { id: track.id,
        track_number: '%02i' % track.track_number,
        title: track.title, 
        artists: track.artists,
        mp3: track.stream_uri,
        release_id: track.release_id,
        waveform: track.waveform_image_uri }
    end
end
