jQuery(document).on 'turbolinks:load', ->
  feed = $('.feed-block').data('feed')
  feed_id = $('.feed-block').data('feedId')

  if feed && App.cable.subscriptions.findAll('{"channel":"WebNotificationsChannel","feed":"'+feed+':'+feed_id+'"}').length == 0
    App.cable.subscriptions.create {
        channel: 'WebNotificationsChannel',
        feed: feed+':'+feed_id
      },
      received: (data) ->
        console.log(data)
        if data.parent_id
          if $('#comment-' + data.parent_id + '-inner').length > 0
            $('#comment-' + data.parent_id + '-inner').after data.object
          else
            $('#comment-' + data.parent_id + '-replies .feed-replies-list').append data.object
        else
          $('.feed-block').prepend data.object
          $("html, body").animate({ scrollTop: $("main") }, 500)

        $('#comment-reply-btn-' + data.parent_id).show()
        $('#topic-post-btn-' + data.parent_id).show().siblings('')
        $('.feed-replies-list .feed-form').remove()
        $('.feed-replies-list').next('.feed-form').remove()

