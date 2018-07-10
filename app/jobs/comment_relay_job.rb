class CommentRelayJob < ApplicationJob
  def perform(object)
    renderer = CommentsController.renderer_with_signed_in_user(User.find object.user_id)
    template = renderer.render(partial: 'comments/comment', 
        locals: { comment: object })

    ActionCable.server.broadcast "#{object.commentable_type.downcase}:#{object.commentable_id}",
      object: template,
      parent_id: object.parent_id
    
    # ActionCable.server.broadcast "messages:#{comment.message_id}:comments",
    #   comment: CommentsController.render(partial: 'comments/comment', locals: { comment: comment })

    # ActionCable.server.broadcast 'web_notifications_channel_one', message: '<p>Hello World!</p>'
  end
end