class FollowsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to choose_profile_path( message: "follows" ), :alert => "Subscribe to get access to this action"
  end
  
  def create
    follow = Follow.new(follow_params)
    follow.user = current_user

    if follow.save
      if follow.followable_type == "User"
        StreamRails.feed_manager.follow_user(follow.user_id, follow.followable_id)
        user_aggregated_feed = StreamRails.feed_manager.get_feed( 'user_aggregated', follow.user_id )
        user_aggregated_feed.follow( follow.followable_type.downcase, follow.followable_id )
      else
        feed = StreamRails.feed_manager.get_feed( follow.followable_type.downcase, follow.followable_id )
        user_feed = StreamRails.feed_manager
            .get_feed( "#{follow.followable_type.downcase}_user_feed", follow.user_id)
        user_feed.follow(feed.slug, follow.followable_id)
      end
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

      if follow.followable_type == "User"
        StreamRails.feed_manager.unfollow_user(follow.user_id, follow.followable_id)
      else
        feed = StreamRails.feed_manager.get_feed( follow.followable_type.downcase, follow.followable_id )
        user_feed = StreamRails.feed_manager
            .get_feed( "#{follow.followable_type.downcase}_user_feed", follow.user_id)
        user_feed.unfollow(feed.slug, follow.user_id)
      end
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