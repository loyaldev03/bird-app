$(document).on('turbolinks:load', function() {
  $('[data-toggle="popover"]').popover({
    trigger: 'focus'
  });

  $('.start-subscription').click(function(e) {
    e.preventDefault();
    $('#payment-user-info').removeClass('d-none');
    $("html, body").animate({ scrollTop: $("#billing-information").offset().top - 120 }, 500);
    if ($(this).hasClass('pro')) {
      $('#subscription_monthly_10').prop('checked', true);
    } else {
      $('#subscription_monthly_7').prop('checked', true);
    }
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
    $('.nav-notify-count').remove();
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
      $(this).find(".comment-inner").hide();
      $(this).find(".comment-inner").slice(-3).show();
  });

  $('.show-more-comments').click(function(){
    $(this).siblings('.feed-replies-list').find('.comment-inner').show();
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

  load_more_feed();

  $('.feed-block').on('click', '.like-comment', function(){
    var type = $(this).data('type');
    var id = $(this).data('id');
    var text = $(this).data('like') == "Like" ? "Unlike" : "Like";
    $(this).text(text).data('like',text);
    $("#like-"+type+"-"+id)[0].click();
    return false;
  });
});

var load_more_feed = function(){
  if($('.feed-block').length > 0 && $('.feed-block').data('feedId') > 0 && $('.feed-block').data('feed') != "topic") {

    var win = $(window);

    win.on('scroll.pagination', function(e) {
      if ($(document).height() - win.height() == win.scrollTop()) {
        $('#loading').show();
        win.off('scroll.pagination');

        var feedId = $('.feed-block').data('feedId');
        var feed, data_feed = $('.feed-block').data('feed');

        switch (data_feed) {
          case 'user':
            feed = "user_aggregated";
            break;
          case 'timeline':
            feed = "timeline_aggregated";
            break;
          case 'release':
            feed = "release";
            break;
          case 'announcement':
            feed = "announcement";
            break;
          default:
            feed = null;
        }
        if(feed) {
          $.ajax({
            url: '/load_more_feed',
            dataType: 'script',
            data: {
              last_item_id: $('#last-item-id').data('itemId'),
              feed: feed,
              feed_id: feedId}
          })
            .done( function() {
              if ($('#loading').length > 0) {
                load_more_feed();
                $('#loading').hide();
              }
            });
        }
      }
    });
  }
} 

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

function countChar(editor, id) {
  var len = editor.text().length;

  if (len >= 140) {
        editor.text( editor.text().substring(0, 140) );
        $('#chars' + id).text(0);
  } else {
       $('#chars' + id).text(140 - len);
  }

}