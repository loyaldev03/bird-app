var current_feed, current_notify;
$(document).on('turbolinks:before-visit', function() {
  if (typeof current_feed !== 'undefined' ) {
    current_feed.unsubscribe();    
  }

  if (typeof current_notify !== 'undefined' ) {
    current_notify.unsubscribe();    
  }
});

$(document).on('turbolinks:load', function() {
  var feedId = $('.feed-block').data('feedId');
  var feed = $('.feed-block').data('feed');
  var userId = $('.dropdown-notify-menu').data('currentUser');

  if(feed && feed != "topic") {

    $.ajax({
      url: '/get_feed_token',
      dataType: 'JSON',
      data: { feed: feed, feed_id: feedId, user_id: userId }
    })
      .done(function(respond) {
        var client = stream.connect(respond.key, null, respond.app_id);

        current_feed = client.feed(feed, feedId, respond.token);
        current_feed.subscribe(feedCallback).then(feedSuccessCallback, feedFailCallback);

        current_notify = client.feed('notification', userId, respond.notify_token);
        current_notify.subscribe(notifyCallback).then(notifySuccessCallback, notifyFailCallback);
      });

  }

  function feedCallback(data) {
    console.log(data);
    if ( data.feed == feed+':'+feedId ) {
      data.new.forEach(function(item){
        $.ajax({
          url: '/add_feed_item',
          dataType: 'script',
          data: { new_item: item, feed: feed, feed_id: feedId }
        });
      });
    }
  }

  function feedSuccessCallback() {
    // console.log('successCallback');
  }

  function feedFailCallback(data) {
    // console.log('failCallback');
    // console.log(data);
  }

  function notifyCallback(data) {
    console.log(data);
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
});
