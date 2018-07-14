class FollowsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to choose_profile_path( message: "follows" ), :alert => "Subscribe to get access to this action"
  end
  
  def create
    follow = Follow.new(follow_params)
    follow.user_id = current_user.id

    if follow.save
      # user_feed = StreamRails.feed_manager.get_user_feed(follow.user_id)
      news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(follow.user_id)[:aggregated]
      
      # user_feed.follow( 'user', follow.followable_id )
      news_aggregated_feed.follow( follow.followable_type.downcase, follow.followable_id )
    end

    render 'toggle_follow', locals: {
              object: follow, 
              text: JSON.parse( params[:text] ), 
              classes: params[:classes] } 
  end

  def destroy
    follow = Follow.find_by_id(params[:id])

    return unless follow

    if follow.user_id == current_user.id
      follow.destroy!

      # user_feed = StreamRails.feed_manager.get_user_feed(follow.user_id)
      news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(follow.user_id)[:aggregated]
      
      # user_feed.unfollow( 'user', follow.followable_id )
      news_aggregated_feed.unfollow( follow.followable_type.downcase, follow.followable_id )
    end

    render 'toggle_follow', locals: {
              object: follow, 
              text: JSON.parse( params[:text] ), 
              classes: params[:classes] } 
  end

  private
    def follow_params
      params.permit(:followable_id, :followable_type)
    end

end