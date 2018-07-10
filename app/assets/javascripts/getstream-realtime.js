$(document).on('turbolinks:load', function() {

  if($('.feed-block').length > 0 && $('.feed-block').data('feedId') > 0) {
    var feedId = $('.feed-block').data('feedId');
    var feed = $('.feed-block').data('feed');
    var userId = $('.dropdown-notify-menu').data('currentUser');
    
    $.ajax({
      url: '/get_feed_token',
      dataType: 'JSON',
      data: { feed: feed, feed_id: feedId, user_id: userId }
    })
      .done(function(respond) {
        var client = stream.connect(respond.key, null, respond.app_id);

        var current_feed = client.feed(feed, feedId, respond.token);
        current_feed.subscribe(feedCallback).then(feedSuccessCallback, feedFailCallback);

        var current_notify = client.feed('notification', userId, respond.notify_token);
        current_notify.subscribe(notifyCallback).then(notifySuccessCallback, notifyFailCallback);
      });

    function feedCallback(data) {
      data.new.forEach(function(item){
        $.ajax({
          url: '/add_feed_item',
          dataType: 'script',
          data: { new_item: item, feed: feed, feed_id: feedId }
        });
      });
    }

    function feedSuccessCallback() {
      // console.log('successCallback');
    }

    function feedFailCallback(data) {
      // console.log('failCallback');
      // console.log(data);
    }

    function notifyCallback(data) {
      data.new.forEach(function(item){
        $.ajax({
          url: '/add_notify_item',
          dataType: 'script',
          data: { new_item: item, user_id: userId }
        });
      });
    }

    function notifySuccessCallback() {
      // console.log('successCallback');
    }

    function notifyFailCallback(data) {
      // console.log('failCallback');
      // console.log(data);
    }
  }
});
