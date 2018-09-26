class FollowsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to choose_profile_path( message: "follows" ), :alert => "Subscribe to get access to this action"
  end
  
  def create
    follow = Follow.new(follow_params)
    follow.user_id = current_user.id
    follow.active = true

    if follow.followable_type == 'User'
      follow.active = false

      if follow.followable.has_role?(:artist) || follow.followable.try(:open_for_follow?)
        follow.active = true
      end
    end

    if follow.save
      news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(follow.user_id)[:aggregated]
      news_aggregated_feed.follow( follow.followable_type.downcase, follow.followable_id )
      
      unless follow.followable_type == "User"
        feed_for_tab = StreamRails.feed_manager
            .get_feed("#{follow.followable_type.downcase}_user_feed", follow.user_id)
        feed_for_tab.follow( follow.followable_type.downcase, follow.followable_id )
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

      news_aggregated_feed = StreamRails.feed_manager.get_news_feeds(follow.user_id)[:aggregated]
      news_aggregated_feed.unfollow( follow.followable_type.downcase, follow.followable_id )

      unless follow.followable_type == "User"
        feed_for_tab = StreamRails.feed_manager
            .get_feed("#{follow.followable_type.downcase}_user_feed", follow.user_id)
        feed_for_tab.unfollow( follow.followable_type.downcase, follow.followable_id )
      end
    end

    render 'toggle_follow', locals: {
              object: follow, 
              text: JSON.parse( params[:text] ), 
              classes: params[:classes] } 
  end

  def reject_request
    @user_id = params[:user_id]

    follow = Follow.unscoped.where("followable_type = 'User' AND followable_id = ? AND user_id = ?",
      current_user.id, @user_id).last

    follow.update_attributes(show_notify: false)
  end

  def accept_request
    @user_id = params[:user_id]
    follow = Follow.unscoped.where("followable_type = 'User' AND followable_id = ? AND user_id = ?",
      current_user.id, @user_id).last
    follow.update_attributes(active: true, show_notify: false)

    Follow.create(user_id: current_user.id, 
                  followable_id: @user_id,
                  followable_type: 'User',
                  show_notify: false)
  end

  def is_seen_requests
    Follow.unscoped.where( show_notify: true, 
                  followable_type: 'User', 
                  followable_id: current_user.id)
      .update_all(show_notify: false)

    render json: {}, status: :ok
  end

  private
    def follow_params
      params.permit(:followable_id, :followable_type)
    end

end