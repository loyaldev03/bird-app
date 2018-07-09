class FeedsController < ApplicationController
  before_action :set_enricher
  before_action :authenticate_user!

  def is_seen
    begin
      feed = StreamRails.feed_manager.get_notification_feed(current_user.id)
      results = feed.get(mark_seen: true)
    rescue Faraday::Error::ConnectionFailed
      results = []
    end

    render json: {}, status: :ok
  end

  def get_feed_token
    token = StreamRails.feed_manager.client.feed(params[:feed], params[:feed_id]).readonly_token
    render json: { token: token, key: ENV['STREAM_API_KEY'], app_id: ENV['STREAM_API_ID'] }
  end

  def add_feed_item
    params.permit!
    @new_item = params['new_item']['verb'].downcase
    @feed = params['feed']

    if @feed == 'user' || @feed == 'timeline'
      @user = User.find_by_id params['feed_id']

      @activity = @enricher.enrich_aggregated_activities([
        { "updated_at" => params['new_item']['time'], 
          "activities" => [params['new_item']],
          "activity_count" => 1}
      ]).first
    else
      @activity = @enricher.enrich_activities([
        params['new_item']
      ]).first
    end

  end

  def load_more
    @feed = params['feed']
    begin
      feed = StreamRails.feed_manager.get_feed(params['feed'], params['feed_id'])
      results = feed.get(limit: 10, id_lt: params['last_item_id'])['results']
    rescue Faraday::Error::ConnectionFailed
      results = []
    end

    if @feed == 'user_aggregated' || @feed == 'timeline_aggregated'
      @user = User.find_by_id params['feed_id']

      @activities = @enricher.enrich_aggregated_activities(results)
    else
      @activities = @enricher.enrich_activities(results)
    end
  end

  private

    def set_enricher
      @enricher = StreamRails::Enrich.new
      @enricher.add_fields([:foreign_id])
    end

end
