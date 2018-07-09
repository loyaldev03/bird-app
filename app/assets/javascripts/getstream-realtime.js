$(document).on('turbolinks:load', function() {

  if($('.feed-block').length > 0 && $('.feed-block').data('feedId') > 0) {
    var feedId = $('.feed-block').data('feedId');
    var feed = $('.feed-block').data('feed');
    
    $.ajax({
      url: '/get_feed_token',
      dataType: 'JSON',
      data: { feed: feed, feed_id: feedId }
    })
      .done(function(respond) {
        var client = stream.connect(respond.key, null, respond.app_id);
        var current_feed = client.feed(feed, feedId, respond.token);

        current_feed.subscribe(callback).then(successCallback, failCallback);
      });

    function callback(data) {
      data.new.forEach(function(item){
        $.ajax({
          url: '/add_feed_item',
          dataType: 'script',
          data: { new_item: item, feed: feed, feed_id: feedId }
        });
      });
    }

    function successCallback() {
      // console.log('successCallback');
    }

    function failCallback(data) {
      // console.log('failCallback');
      // console.log(data);
    }
  }
});
