class HomeController < ApplicationController
  include UsersHelper
  include StreamRails::Activity

  before_action :authenticate_user!, 
      except: [:index, :about, :birdfeed, :share, :report, :pricing]
  before_action :set_notifications, only: [:about, :birdfeed, :pricing]

  def index
    @slider = SliderImage.all.ordered

    @leader_users = leaderboard_query(1, 10, true)

    @artists = User.with_role(:artist)
                   .order('created_at ASC')
                   .includes(:artist_info)
                   .limit(20)

    @releases = Release.published.where(
      'published_at <= :now AND (published_at >= :user_max OR available_to_all = true)',
      now: DateTime.now,
      user_max: DateTime.now - 1.month
    ).order('published_at DESC')

    @badge_kinds = BadgeKind.visible

    #TODO decrease count of queries
    # @leader_points = {}

    # @badge_points = BadgePoint.all.freeze

    # @leader_users.each do |user|
    #   @leader_points["leader_#{user.id}"] ||= {}
    #   @badge_kinds.each do |kind|
    #     @leader_points["leader_#{user.id}"]["kind#{kind.id}"] = @badge_points.where(user_id: user.id, badge_kind_id: kind.id).pluck(:value).sum
    #   end
    # end
  end

  def about
  end

  def birdfeed
    begin
      feed = StreamRails.feed_manager.get_feed('masterfeed', 1)
      results = feed.get()['results']
    rescue Faraday::Error::ConnectionFailed
      results = []
    end
    
    @enricher = StreamRails::Enrich.new
    @enricher.add_fields([:foreign_id])
    @activities = @enricher.enrich_activities(results)
  end

  def share
    if params[:subtype] && params[:subtype_id]
      object = "#{params[:subtype].capitalize}:#{params[:subtype_id]}"
      _object_id = params[:subtype_id]
      verb = params[:subtype].capitalize
    else
      object = "#{params[:type].capitalize}:#{params[:type_id]}"
      _object_id = params[:type_id]
      verb = params[:type].capitalize
    end

    share = Share.create(
          user_id: current_user.try(:id),
          shareable_type: verb,
          shareable_id: _object_id,
          social: params[:social]
      )

    if current_user
      feed = StreamRails.feed_manager.get_user_feed( current_user.id )
      activity = {
        actor: "User:#{current_user.id}",
        verb: verb,
        object: object,
        foreign_id: "Share",
        social: params[:social],
        time: DateTime.now.iso8601
      }

      feed.add_activity(activity)

      current_user.change_points( 'share', params[:type].capitalize )
    end

    render json: {}
  end

  def badge_notify
    return unless current_user

    badges = []

    current_user.badge_levels.each do |level|
      unless level.notified?
        badges << level.badge_id
        level.update_attributes( notified: true )
      end
    end

    render json: { badges: badges }
  end

  def report
    report = Report.create(
          user_id: current_user.try(:id),
          reportable_type: params[:type],
          reportable_id: params[:id],
          ip_address: request.remote_ip,
          text: params[:text]
      )

    admins = User.with_role(:admin)

    admins.each do |user|
      next if current_user && user.id == current_user.id

      feed = StreamRails.feed_manager.get_notification_feed( user.id )

      activity = {
        actor: "User:#{current_user.try(:id)}",
        verb: "Report",
        object: "#{params[:type]}:#{params[:id]}",
        foreign_id: "Report:#{report.id}",
        time: DateTime.now.iso8601
      }

      feed.add_activity(activity)
    end

  end

  def pricing
    
  end

end
