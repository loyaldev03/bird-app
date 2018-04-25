class TracksController < ApplicationController
  def show
    @track = Track.find(params[:id])
  end

  def get_tracks
    # if cuttent_user && current_user.playlist.present?
    #   tracks = []

    #   current_user.playlist.tracks.split(',').each do |track_id|
    #     track = Track.find( track_id )
    #     artists = track.users.pluck(:name).join(' feat. ')

    #     tracks << {
    #       title: track.title,
    #       artists: artists,
    #       mp3: track.get_url # TODO check for subscription
    #     }
    #   end

    #   if current_user.playlist.current_track.present?
    #     current_track_data = current_user.playlist.current_track.split(':')
    #     current_track = { index: current_track_data[0], time: current_track_data[1] }
    #   else
    #     current_track = { index: 0, time: 0 }
    #   end
    # else
      # tracks = Track.last(5).map do |track|
      #   artists = track.users.pluck(:name).join(' feat. ')
      #   { title: track.title, artists: artists, mp3: track.get_url } # TODO check for subscription
      # end

      tracks = [
        {
          title:"Tempered Song",
          artists: "Artist 1 feat. Artist 2",
          mp3:"https://birdfeed-prod.s3.amazonaws.com/tracks/7d/f4fdb0c57611e7afe977749cd8a258/03. Catz n Dogz - Drop It - Sample - Dirtybird.mp3"
        },
        {
          title:"Hidden",
          artists: "Artist 3 feat. Artist 4",
          mp3:"https://birdfeed-prod.s3.amazonaws.com/tracks/80/1126f0c57611e7989f3b5145cbf698/04. SecondCity  Tyler Rowe - I Enter - Sample - Dirtybird.mp3"
        },
        {
          title:"Lentement",
          artists: "Artist 5 feat. Artist 6",
          mp3:"https://birdfeed-prod.s3.amazonaws.com/tracks/7e/11fb90c57611e78c72eb88ceec719c/05. Ghostea - Breathing Room - Sample - Dirtybird.mp3"
        }
      ]
      current_track = { index: 2, time: 10 }
    # end

      render json: { tracks: tracks, current_track: current_track }

  end

  def download
    redirect_to new_user_registration_path and return unless current_user
    redirect_to choose_profile_path and return if current_user.subscription_type.blank?

    @release = Release.find(params[:id])
    redirect_to choose_profile_path unless @release.user_allowed?(current_user)
  end
end
