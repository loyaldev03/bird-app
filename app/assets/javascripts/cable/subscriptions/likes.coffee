jQuery(document).on 'turbolinks:load', ->

  if App.cable.subscriptions.findAll('{"channel":"LikesChannel","feed":"likes"}').length == 0
    App.cable.subscriptions.create {
        channel: 'LikesChannel',
        feed: 'likes'
      },
      received: (data) ->
        console.log(data)
        button = $('#like-' + data.likeable_type + '-' + data.likeable_id)

        if data.style == 'release' || data.style == 'thumbup'
          console.log data.count
          if data.count > 0
            button.siblings('.likes-count').html('(' + data.count + ')')
          else
            button.siblings('.likes-count').html('')

        else if data.style == 'thumbup-reply'
          count_part = $('#likes-count-' + data.likeable_type + '-' + data.likeable_id + ' .likes-count')

          if data.count > 0
            count_part.html(data.count)
          else
            count_part.html('')
