jQuery(document).on 'turbolinks:load', ->
  feed = $('.feed-block').data('feed');
  feed_id = $('.feed-block').data('feedId');

  App.cable.subscriptions.create {
      channel: 'WebNotificationsChannel',
      feed: feed+':'+feed_id
    },
    received: (data) ->
      if $('#Comment-' + data.parent_id+'.feed-replies').length > 0
        parent = $('#Comment-' + data.parent_id)
      else
        parent = $('#message-' + data.parent_id)
        commentsCount = $('.comments-count' + data.parent_id)
        commentsCount.text(parseInt(commentsCount.text()) + 1)

      topCommentsCount = parent.closest('.feed-item').find('.comments-count')

      topCommentsCount.text(parseInt(topCommentsCount.text()) + 1)
    
      $('#comment_body-' + data.parent_id).val('').closest('.feed-form').remove()
      
      if parent.find('.feed-replies-list').length > 0
        parent.find('.feed-replies-list').append data.object
      else
        parent.append data.object

      $('#comment-reply-' + data.parent_id).show()
