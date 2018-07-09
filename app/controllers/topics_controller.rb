class TopicsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notifications, only: [:show]

  breadcrumb 'Categories', :chirp_index_path, match: :exact

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to choose_profile_path( message: "create topics" ), :alert => "Subscribe to get access to this action"
  end

  def show
    @topic = Topic.find(params[:id])

    if ( @topic.user && @topic.user.has_role?(:artist) ) || !@topic.see_to_all
      authorize! :read, @topic
    end

    if params[:chirp_id].present?
      @category = TopicCategory.find(params[:chirp_id])
    else
      @category = @topic.category
    end
    @new_post = Post.new

    @new_post.feed_images.build

    breadcrumb @category.title, chirp_path(@category), match: :exact
    breadcrumb @topic.title, chirp_topic_path(@category, @topic), match: :exact
  end

  def create
    topic = Topic.new(topic_params)

    authorize! :create, topic

    topic.user_id = current_user.id
    if topic.save
      flash[:notice] = 'Topic was created'

      # user_feed = StreamRails.feed_manager.get_user_feed( current_user.id )
      notify_feed = StreamRails.feed_manager.get_notification_feed( current_user.id )
      news_aggregated_feed = StreamRails.feed_manager.get_news_feeds( current_user.id )[:flat]
      # user_feed.follow( 'topic', topic.id )
      notify_feed.follow( 'topic', topic.id )
      news_aggregated_feed.follow( 'topic', topic.id )

    else
      flash[:alert] = topic.errors.full_messages.join(', ')
    end

    redirect_to chirp_path(topic.category)
  end

  def topic_params
    params.require(:topic).permit(:text, :title, :category_id)
  end
end
