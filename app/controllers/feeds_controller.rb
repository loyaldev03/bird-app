class FeedsController < ApplicationController
  before_action :create_enricher
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
    token = StreamRails.feed_manager.client.feed(params[:feed], current_user.id).token
    render json: { token: token, key: ENV['STREAM_API_KEY'], app_id: ENV['STREAM_API_ID'] }
  end

  def add_feed_item
    params.permit!
    @feed = params['feed']['verb'].downcase

    @enricher = StreamRails::Enrich.new
    @enricher.add_fields([:foreign_id])

    @activity = @enricher.enrich_aggregated_activities([
      {"updated_at" => params['feed']['time'], "activities" => [params['feed']]}
    ]).first
  end

  private

    def create_enricher
      @enricher = StreamRails::Enrich.new
      @enricher.add_fields([:foreign_id])
    end

end
