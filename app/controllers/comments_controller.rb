class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  load_and_authorize_resource

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to choose_profile_path( message: "comments" ), :alert => "Subscribe to get access to this action"
  end

  def show
    comment = Comment.find params[:id]

    if comment.commentable.try(:has_role?, :artist)
      action = 'artist'
    elsif comment.commentable.try(:has_role?, :admin)
      action = 'admin'
    else
      action = 'show'
    end

    redirect_to( url_for(
        controller: comment.commentable_type.pluralize.downcase, 
        action: action,
        id: comment.commentable_id,
        anchor: "message-#{comment.id}" ) )
  end

  def create
    @comment = Comment.new(comment_params)

    if current_user.has_role?(:admin)
      @comment.user_id = params[:comment][:user_id] || current_user.id
    elsif @comment.commentable_type == "User" &&
            @comment.parent.nil? &&
            @comment.commentable_id != current_user.id
      redirect_back(fallback_location: root_path) and return
    else
      @comment.user_id = current_user.id
    end


    logger.warn(@comment.errors.full_messages) unless @comment.save

  end

  def edit
    @comment = Comment.find(params[:id])
  end

  def update
    @comment = Comment.find(params[:id])
    @comment.edited_at = DateTime.now

    @comment.update_attributes(comment_params) if current_user.id == @comment.user_id

    flash[:notice] = 'Comment was updated'
  end

  def destroy
    @comment = Comment.find(params[:id])

    @comment.destroy if current_user.id == @comment.user_id

    flash[:notice] = 'comment was deleted'
  end
 
  def reply_form
    @comment_id = params[:comment_id]
    @commentable_id = params[:commentable_id]
    @commentable_type = params[:commentable_type]
    @comment_hash = SecureRandom.hex
    @new_comment = Comment.new
    @new_comment.feed_images.build
  end


  private

    def comment_params
      params.require(:comment).permit(:commentable_type, :commentable_id, 
        :body, :title, :parent_id, :likes_count, :shares_count, :comment_hash,
        feed_images_attributes: [:id, :feedable_id, :feedable_type, :image, :_destroy])
    end
end
