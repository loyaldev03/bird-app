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
        render json: track_as_json(track_presenter)
      }
    end
  end

  def liked
    @user = User.find params[:user_id]
    @tracks = @user.liked_by_type('Track').map do |_track|
      track_presenter = TrackPresenter.new(_track, current_user)
    end
  end

  def play
    case params[:source_type]
    when 'liked'
      user = User.find(params[:source_id])
      tracks = user.liked_by_type('Track')
    else
      tracks = params[:source_type]
          .classify
          .constantize
          .find(params[:source_id])
          .tracks
    end

    tracks = tracks.order(track_number: :asc) if params[:source_type] == 'release'

    tracks = tracks.map do |_track|
      track = TrackPresenter.new(_track, current_user)
      track_as_json(track)
    end

    render json: { tracks: tracks }
  end

  def fill_track_title
    track = Track.find(params[:track_id])
    @track = TrackPresenter.new(track, current_user)
    @release = ReleasePresenter.new(track.release, current_user)
  end

  def fill_bottom_player
    track = Track.find(params[:track_id])
    @track = TrackPresenter.new(track, current_user)
  end

  def download
    @track = Track.find(params[:id])

    unless @track.user_allowed?(current_user)
      raise ActionController::RoutingError, 'Not Found'
    end

    #special conditions for users from previous version of site
    if current_user.subscription_length == 'monthly_10' ||
         current_user.subscription_length == 'monthly_old'

      if current_user.download_credits < 1
        redirect_to root_path, alert: "You have reached the limit of track downloads" and return
      end
      
      current_user.decrement!(:download_credits)
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

  private 

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
