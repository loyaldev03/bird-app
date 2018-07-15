class CommentRelayJob < ApplicationJob
  def perform(object)
    renderer = CommentsController.renderer_with_signed_in_user(User.find object.user_id)

    if object.class.to_s == "Comment"

      template = renderer.render(partial: 'comments/comment', 
          locals: { comment: object })
      channel = "#{object.commentable_type.downcase}:#{object.commentable_id}"

    elsif object.class.to_s == "Post" && object.parent_id.present?

      template = renderer.render(partial: 'comments/comment', 
          locals: { comment: object })
      channel = "topic:#{object.topic_id}"

    else

      template = renderer.render(partial: 'posts/post', 
          locals: { post: object })
      channel = "topic:#{object.topic_id}"

    end

    ActionCable.server.broadcast channel,
      model: object.class.to_s,
      object: template,
      parent_id: object.parent_id
    
  end
end