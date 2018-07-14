class TracksController < ApplicationController
  def show
    track = Track.find(params[:id])
    track_presenter = TrackPresenter.new(track, current_user)

    if track_presenter.users.any?
      artists = track_presenter.users.map(&:name).join(' feat. ')
    else
      artists = track_presenter.artist
    end

    respond_to do |format|
      format.html { redirect_to track.release }
      format.json {
        render json: { 
          track: { 
            id: track_presenter.id,
            track_number: track_presenter.track_number,
            title: track_presenter.title, 
            artists: artists,
            mp3: track_presenter.stream_uri,
            release_id: track_presenter.release_id,
            waveform: track_presenter.waveform_image_uri
          } 
        }
      }
    end
  end

  def get_tracks
    if current_user && current_user.playlists.present?
      tracks = []

      if params[:playlist].present?
        playlist = Playlist.find params[:playlist]
      elsif current_user.current_playlist_id.present?
        playlist = current_user.current_playlist

        unless playlist
          playlist = current_user.playlists.order(updated_at: :desc).first
          current_user.update_attributes(current_playlist_id: playlist.id)
        end
      else
        playlist = current_user.playlists.order(updated_at: :desc).first
        current_user.update_attributes(current_playlist_id: playlist.id)
      end

      playlist.tracks.to_s.split(',').each do |track_id|
        track_presenter = TrackPresenter.new(Track.find( track_id ), current_user)

        if track_presenter.artist_as_string && track_presenter.artist.present?
          artists = track_presenter.artist
        elsif track_presenter.users.any?
          artists = track_presenter.users.map(&:name).join(' feat. ')
        else
          artists = track_presenter.artist
        end

        tracks << {
          id: track_presenter.id,
          track_number: track_presenter.track_number,
          title: track_presenter.title, 
          artists: artists,
          mp3: track_presenter.stream_uri,
          release_id: track_presenter.release_id,
          waveform: track_presenter.waveform_image_uri
        }
      end

      if playlist.current_track.present?
        current_track_data = playlist.current_track.split(':')
        current_track = { index: current_track_data[0].to_i, time: current_track_data[1].to_i }
      else
        current_track = { index: 0, time: 0 }
      end
    else
      tracks = Track.where.not('sample_uri is NULL').order(created_at: :asc).last(1).map do |track|
        track_presenter = TrackPresenter.new(track, current_user)

        if track_presenter.artist_as_string && track_presenter.artist.present?
          artists = track_presenter.artist
        elsif track_presenter.users.any?
          artists = track_presenter.users.map(&:name).join(' feat. ')
        else
          artists = track_presenter.artist
        end

        { id: track_presenter.id,
          track_number: track_presenter.track_number,
          title: track_presenter.title, 
          artists: artists,
          mp3: track_presenter.stream_uri,
          release_id: track_presenter.release_id,
          waveform: track_presenter.waveform_image_uri }
      end

      current_track = { index: 0, time: 0 }

      if current_user
        playlist = Playlist.create(
          user: current_user, 
          tracks: tracks.map{|t| t[:id]}.join(','), 
          current_track: "0:0" )
        current_user.update_attributes(current_playlist_id: playlist.id)
      end
    end

    if current_user
      playlist_name_form = render_to_string( 
          partial: 'playlists/change_name', 
          locals: { playlist: playlist } )
      creator = current_user.current_playlist.user.name 
    else
      playlist_name_form = ""
      creator = ""
    end

    render json: { tracks: tracks, 
            current_track: current_track,
            playlist_name_form: playlist_name_form,
            creator: creator}
  end

  def fill_track_title
    track = Track.find(params[:track_id])
    @track = TrackPresenter.new(track, current_user)
    @release = ReleasePresenter.new(track.release, current_user)
  end

  def download
    @track = Track.find(params[:id])

    unless @track.user_allowed?(current_user)
      raise ActionController::RoutingError, 'Not Found'
    end

    #special conditions for users from previous version of site
    if current_user.subscription_length =='monthly_10' ||
         current_user.subscription_length == 'monthly_old'
      
      if current_user.downloads.where("created_at > ?",current_user.braintree_subscription_expires_at - 1.month).count >= 10
        redirect_to root_path, alert: "You have reached the limit of track downloads" and return
      end
    end

    @format = params[:format] || :mp3_320
    tf = TrackFile.find_by(track: @track, format: TrackFile.formats[@format])
    Download.create(user: current_user, track: @track, format: Download.formats[@format])

    redirect_to S3_BUCKET.object(tf.s3_key).presigned_url(:get, response_content_disposition: 'attachment')
  end

  def track_listened
    if current_user
      track = Track.find params[:id]
      track.increment! :listened_count

      current_user.change_points( 'listen', 'Track' )
    end

    render json: {}
  end
end
