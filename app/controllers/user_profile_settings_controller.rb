class UserProfileSettingsController < ApplicationController
  include UsersHelper
  include ReleasesHelper
  
  before_action :authenticate_user!
  before_action :set_notifications, only: [:rewards, :egg_credits, :headers, :skins, :downloads, :billing_order_history, :friends, :artists, :releases, :chirp_feeds, :notifications]
  before_action :set_user
	def rewards
	end	

	def egg_credits 
	end

	def headers
	end

	def skins
	end

	def downloads
		@downloads = current_user.downloads
	end

	def billing_order_history
		@billing_order_histories = current_user.billing_order_histories 
	end

	def friends
	    _friends = current_user.followed_users.where("users.id NOT IN (?)", User.with_role(:artist).pluck(:id))
	    @friends = []
	    _friends.map do |friend|
	    	friend_json = JSON.parse(friend.to_json)
	    	sub_friends = friend.followed_users.where("users.id NOT IN (?)", User.with_role(:artist).pluck(:id))
	    	@friends.push({
	    		info: friend,
	    		number_of_friends: sub_friends.length
	    	})
	    end
	    @friends
	end

	def artists
	    @artists = current_user.followed_users.with_role(:artist)
	end

	def releases
		release_follows = current_user.follows.where(followable_type: "Release")		
		@releases = []
		release_follows.each do |follow|
			release = Release.find(follow.followable_id)
			@releases.push release
		end
		@releases
	end

	def chirp_feeds
		release_follows = current_user.follows.where(followable_type: "Topic")		
		@topics = []
		release_follows.each do |follow|
			topic = Topic.find(follow.followable_id)
			@topics.push topic
		end
		@topics
	end

	def notifications
		@notification_settings = current_user.notification
	end

private
	def set_user
		@user = current_user
	end
end
