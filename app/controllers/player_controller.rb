class PlayerController < ApplicationController
  include ApplicationHelper
  
  before_action :set_vars
  before_action :set_notifications, 
      only: [:liked_tracks, :recently_tracks, :downloaded_tracks, :favorites,
        :liked_playlists, :connect, :listen]
  
  def liked_tracks
    @tracks = @user.liked_by_type('Track').map do |_track|
      TrackPresenter.new(_track, current_user)
    end

    @tracks.compact!
  end

  def recently_tracks
    @with_index = true
    @tracks = @user.recently_items.map do |item|
      TrackPresenter.new(item.track, current_user) if item.track
    end

    @tracks.compact!
  end

  def downloaded_tracks
    @tracks = @user.downloads.map do |d| 
      TrackPresenter.new(d.track, current_user) if d.track
    end

    @tracks.compact!
  end

  def favorites
    @playlists = @user.liked_by_type('Playlist').limit(3)

    @tracks = @user.liked_by_type('Track').limit(7).map do |_track|
      TrackPresenter.new(_track, current_user)
    end

    @releases = @user.liked_by_type('Release').limit(3).map do |_release|
      ReleasePresenter.new(_release, current_user)
    end

    @tracks.compact!
    @releases.compact!
  end

  def liked_playlists
    @playlists = @user.liked_by_type('Playlist')
  end

  def connect
    if get_setting('main-area-promo')
      @main_area = { link: get_setting('main-area-promo'), 
                     img: get_setting_res('main-area-promo')}
    else
      @main_area = nil
    end
  end

  def listen
    @top_releases = Release.published.order(created_at: :desc).limit(3)
    top_tracks_ids = 
      RecentlyItem.group(:track_id)
                  .count
                  .sort_by {|k,v| v}
                  .reverse[0..4]
                  .map {|a| a[0]}
    @top_tracks = top_tracks_ids.map { |id| Track.find_by_id id }.compact
    @top_playlists = Playlist.all.order(created_at: :desc).limit(3)
  end

  private

    def set_vars
      @user = User.find params[:player_id]
      @playlists = @user.playlists
    end

end
