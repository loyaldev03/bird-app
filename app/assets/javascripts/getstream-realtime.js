$(document).on('turbolinks:load', function() {
  if($('.feed-block').length > 0 && $('.feed-block').data('userId') > 0) {
    $.ajax({
      url: '/get_feed_token',
      dataType: 'JSON',
      data: { feed: 'user' }
    })
      .done(function(respond) {
        var userId = $('.feed-block').data('userId');
        var feed = $('.feed-block').data('feed');
        var client = stream.connect(respond.key, null, respond.app_id);
        var user1 = client.feed(feed, userId, respond.token);

        user1.subscribe(callback).then(successCallback, failCallback);
      });

    function callback(data) {
        data.new.forEach(function(item){
          $.ajax({
            url: '/add_feed_item',
            dataType: 'script',
            data: { feed: item }
          });
        });
    }

    function successCallback() {
    }

    function failCallback(data) {
    }
  }
});
