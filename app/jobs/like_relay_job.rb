class LikeRelayJob < ApplicationJob
  def perform(object, action)
    renderer = LikesController.renderer_with_signed_in_user(User.find object.user_id)

    likeable = object.likeable

    if likeable.class.to_s == 'Release' || likeable.class.to_s == 'Announcement'
      style = 'release'
    elsif likeable.class.to_s == 'Comment' || likeable.class.to_s == 'Post'

      if likeable.parent_id.present?
        style = 'thumbup-reply'
      else
        style = 'thumbup'
      end

    else
      style = false
    end

    if action == 'create'
      count = likeable.try(:likes_count) ? likeable.likes_count : likeable.likes.count
    else
      count = likeable.try(:likes_count) ? likeable.likes_count - 1 : likeable.likes.count - 1
    end

    ActionCable.server.broadcast 'likes',
      likeable_type: object.likeable_type,
      likeable_id: object.likeable_id,
      style: style,
      count: count
  end
end
