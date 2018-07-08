$(document).on('turbolinks:load', function() {
  $('[data-toggle="popover"]').popover({
    trigger: 'focus'
  });

  $('.start-subscription').click(function(e) {
    e.preventDefault();
    $('#payment-user-info').removeClass('d-none');
  });

  const notify = (selector) => {
    let obj = $(selector);
    if(obj.text().length > 0) {
      obj.show();
      setTimeout(function(){
        obj.fadeOut('slow');
      },3000);
    }
  };
  notify('.notice');
  notify('.alert');

  $('.modal-blured').on('show.bs.modal', function () {
    $(this).siblings('.main-container').css({'filter': 'blur(15px)'});
  });

  $('.modal-blured').on('hide.bs.modal', function (e) {
    if ($('.modal-backdrop.show').length == 1) {
      $(this).siblings('.main-container').css({'filter': 'blur(0px)'});
    }
  });

  $('#searchModal').on('shown.bs.modal', function () {
    var client = algoliasearch("TOQ4XQOWDP", "90f548a9f6bb9108464d081db4c6a29a")
    var tracks = client.initIndex('Track');
    var releases = client.initIndex('Release');//.setSettings({attributesToSnippet: ['text:3','title']});
    var users = client.initIndex('User');
    var topics = client.initIndex('Topic');
    var posts = client.initIndex('Post');

    autocomplete('#aa-search-input', {}, [
        {
          source: autocomplete.sources.hits(tracks, { hitsPerPage: 3 }),
          displayKey: 'title',
          templates: {
            header: '<div class="aa-suggestions-category">Tracks</div>',
            suggestion: function(suggestion) {
              return '<a href="/tracks/'+suggestion.objectID+'"><span>' +
                suggestion._highlightResult.title.value + '</span></a>';
            }
          }
        },
        {
          source: autocomplete.sources.hits(releases, { hitsPerPage: 3 }),
          displayKey: 'title',
          templates: {
            header: '<div class="aa-suggestions-category">Releases</div>',
            suggestion: function(suggestion) {
              return '<a href="/releases/'+suggestion.objectID+'"><span><i>' +
                suggestion._highlightResult.title.value + '</i> '
                  + suggestion._highlightResult.text.value + '</span></a>';
            }
          }
        },
        {
          source: autocomplete.sources.hits(users, { hitsPerPage: 3 }),
          displayKey: 'first_name',
          templates: {
            header: '<div class="aa-suggestions-category">Users</div>',
            suggestion: function(suggestion) {
              return '<a href="/users/'+suggestion.objectID+'"><span>' +
                suggestion._highlightResult.first_name.value + ' ' +
                suggestion._highlightResult.last_name.value +'</span></a>';
            }
          }
        },
        {
          source: autocomplete.sources.hits(topics, { hitsPerPage: 3 }),
          displayKey: 'title',
          templates: {
            header: '<div class="aa-suggestions-category">Topics</div>',
            suggestion: function(suggestion) {
              return '<a href="/topics/'+suggestion.objectID+'"><span>' +
                suggestion._highlightResult.title.value 
                  + suggestion._highlightResult.text.value + '</span></a>';
            }
          }
        },
        {
          source: autocomplete.sources.hits(posts, { hitsPerPage: 3 }),
          displayKey: 'text',
          templates: {
            header: '<div class="aa-suggestions-category">Posts</div>',
            suggestion: function(suggestion) {
              return '<a href="/chirp/'+suggestion.objectID+'"><span>' +
                suggestion._highlightResult.text.value + '</span>';
            }
          }
        }
    ]);
    
    $('#aa-search-input').focus();
  });

  let avatar_form = document.querySelector('#change-avatar');
  $(avatar_form).find('#user_avatar').change(function(){
    avatar_form.dispatchEvent(new Event('submit', {bubbles: true}));
  });

  $('.truncated-description').on('click', '.truncated-long', function(){
    $(this).hide();
    $(this).prev('article').hide();
    $(this).next('article').show();
    $('.truncated-short').show();
    return false;
  });

  $('.truncated-description').on('click', '.truncated-short', function(){
    $(this).siblings('article').show();
    $(this).siblings('article').last().hide();
    $(this).hide();
    $('.truncated-long').show();
    return false;
  });

  $('.dropdown-notify-menu').on("show.bs.dropdown", function(event){
    $.get( "/is_seen", function() {});
    $('.nav-notify-count').hide();
  });

  $('.dropdown-notify-menu').on("hide.bs.dropdown", function(event){
    $('.dropdown-notify-menu .notify-seen').removeClass('notify-seen');
  });

  $('.notice').click(function(){$(this).hide()});
  $('.alert').click(function(){$(this).hide()});

  $('.scroll-bottom').click(function(){
    $("html, body").animate({ scrollTop: $(document).height() }, 500);
  });

  $('.feed-replies-list').each(function(){
    $(this).find("[id^='message-']").each(function(){
      $(this).find("[id^='message-']").hide();
      $(this).find("[id^='message-']").slice(-3).show();
    });
  });

  $('.show-more-comments').click(function(){
    $(this).siblings('.feed-replies-list').find('div').show();
    $(this).hide();
    return false;
  });

  if (window.location.hash !== "") {
    $('html, body').animate({
      scrollTop: $(window.location.hash).offset().top - 120
    }, 600, function(){});
  }

  $(".emoji-area").emojioneArea({search: false, recentEmojis: false, pickerPosition: 'bottom'});

  dragDropAttach();

  $(document).on('change', ".image-attach + [type='file']", function(){
    var remove_button = $('<button class="c-btn-blue c-btn-sm ml-2">remove</button>');

    $(this).siblings('span').remove();
    $(this).siblings('button').remove();
    $(this).after(remove_button)
        .after($('<span>'+$(this).val().split('/').pop().split('\\').pop()+'</span>'));

    remove_button.click(function(){
      $(this).siblings("[type='file']").val('');
      $(this).siblings('span').remove();
      $(this).remove();
    });

  });

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

function dragDropAttach() {
  setTimeout( function() {
    var $dropContainer = $('.emojionearea');
    
    if ($dropContainer.length > 0){
      dropContainer = $dropContainer[0];

      dropContainer.ondragleave = function(e) {
        $dropContainer.removeClass('drop-here');
      };

      dropContainer.ondragover = dropContainer.ondragenter = function(e) {
        $dropContainer.addClass('drop-here');
        e.preventDefault();
      };

      dropContainer.ondrop = function(e) {
        $dropContainer.removeClass('drop-here');
        var file_input = $(dropContainer).closest('form').find("[type='file']")[0];
        file_input.files = e.dataTransfer.files;
        $(file_input).trigger('change');
        e.preventDefault();
      };
    }
  },200);
}
