class PostsController < ApplicationController
  before_action :authenticate_user!

  def show
    post = Post.find params[:id]

    redirect_to topic_path( post.topic, anchor: "message-#{post.id}" )
  end
  
  def create
    @topic = Topic.find(params[:post][:topic_id])
    @post = Post.new(post_params)
    @post.user_id = current_user.id
    if @post.save
      flash[:notice] = 'Post was created'
    else
      flash[:alert] = @post.errors.full_messages.join(', ')
    end
  end

  def edit
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])
    @post.edited_at = DateTime.now

    @post.update_attributes(post_params) if current_user.id == @post.user_id

    flash[:notice] = 'Post was updated'
  end

  def destroy
    @post = Post.find(params[:id])

    @post.destroy if current_user.id == @post.user_id

    flash[:notice] = 'Post was deleted'
  end

  def reply_form
    @post_id = params[:post_id]
    @topic_id = params[:topic_id]
    @post_hash = SecureRandom.hex
    @new_post = Post.new
    @new_post.feed_images.build
  end

  protected

    def post_params
      params.require(:post).permit(:text, :topic_id, :parent_id, :post_hash,
        feed_images_attributes: [:id, :feedable_id, :feedable_type, :image, :_destroy])
    end
end
