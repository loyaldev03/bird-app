$(document).on('turbolinks:load', function() {
  $('[data-toggle="popover"]').popover({
    trigger: 'focus'
  });

  $('.select').select2();

  $('.plan-block').click(function(){
    $('.plan-block').removeClass('active');
    $(this).addClass('active');
    var type = $(this).data('type');
    var period = $('.switcher').prop('classList').contains('monthly') ? "monthly" : "yearly";
    $('.selected-type').text(type);

    $("input:radio[name='subscription']").prop('checked',false);

    if (type == 'chirp') {
      $("input[data-type='chirp']").prop('checked',true);
      $('.selected-period').text('free');
      $('.signup-billing-cost').text('free');
      $('.signup-billing-time').text('never');
      $('.signup-payed').hide();
      $('.signup-free').show();
    } else {
      var radio_btn = $("input[data-type='"+type+"'][data-period='"+period+"']");
      radio_btn.prop('checked',true);
      $('.selected-period').text(period);
      $('.signup-billing-cost').text(radio_btn.data('cost'));
      $('.signup-billing-time').text(thirtyDaysFromNow());
      $('.signup-payed').show();
      $('.signup-free').hide();
    }
  });

  $('.signup-free-btn').click(function(e){
    e.preventDefault();
    var terms = $('#free-terms-and-conditions');
    var conduct = $('#free-code-of-conduct');

    if (terms.prop("checked") && conduct.prop("checked")) {
      $.ajax('/terms_and_conduct');
      window.location.replace('/success_signup');
    } else {
      terms.siblings('label').find('a').css({'background-color':'pink'});
      conduct.siblings('label').find('a').css({'background-color':'pink'});
    }
  });

  function thirtyDaysFromNow() {
    var now = Date.now();
    return new Date(now + 30*24*60*60*1000).toLocaleDateString();
  }

  $('.switcher').click(function(){
    switchPlanPeriod(false, this);
  });

  $('.switcher-annualy').click(function(){
    switchPlanPeriod('annualy',this);
  });

  $('.switcher-monthly').click(function(){
    switchPlanPeriod('monthly',this);
  });

  function switchPlanPeriod(to=false, self) {
    if (to && to == 'monthly') {
      $(self).siblings('.switcher').addClass('monthly');
      changePeriod('monthly');
    } else if (to && to == 'annualy') {
      $(self).siblings('.switcher').removeClass('monthly');
      changePeriod('yearly');
    } else {
      $(self).toggleClass('monthly');
      changePeriod();
    }

    function changePeriod(to=null) {
      var current = $("input:radio[name='subscription']:checked");
      var type = current.data('type');
      if (type == 'chirp') return;

      if (to) {
        current.prop('checked',false);
        var other = $("input[data-type='"+  type +"'][data-period='"+to+"']");
        other.prop('checked',true);
        $('.selected-period').text(to);
        $('.signup-billing-cost').text(other.data('cost'));
      } else {
        current.prop('checked',false);
        var other = $("input[data-type='"+ type +"']").not(current);
        other.prop('checked',true);
        $('.selected-period').text(other.data('period'));
        $('.signup-billing-cost').text(other.data('cost'));
      }
    }
  }

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

  $(document).on('hide.bs.modal', '.modal-blured', function (e) {
    $('.main-container').css({'filter': 'unset'});
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
      $(this).children(".comment-outer").hide();
      $(this).children(".comment-outer").slice(-3).show();
  });

  $('.nested-messages').each(function(){
      $(this).children(".comment-outer").hide();
      $(this).children(".comment-outer").slice(-3).show();
  });

  $('.show-more-comments').click(function(){

    $(this).siblings('.feed-replies-list').children('.comment-outer').show();
    $(this).siblings('.comment-outer').show();
        // .siblings('.nested-messages').removeClass('replies-hidden');
    $(this).hide();
    return false;
  });

  if (window.location.hash !== "") {
    $('html, body').animate({
      scrollTop: $(window.location.hash).offset().top - 120
    }, 600, function(){});
  }

  $(".emoji-area").emojioneArea({
                    search: false,
                    recentEmojis: false,
                    pickerPosition: 'bottom',
                    events: {
                      keyup: function (editor, event) {
                        countChar(editor, '');
                     }
                   }
        });

  dragDropAttach();

  $(document).on('change', ".image-attach + [type='file']", function(){
    var remove_button = $('<button class="c-btn-blue c-btn-sm ml-2">remove</button>');

    $(this).siblings('span.filename').remove();
    $(this).siblings('button').remove();
    $(this).after(remove_button)
        .after($('<span class="filename">'+$(this).val().split('/').pop().split('\\').pop()+'</span>'));

    remove_button.click(function(){
      $(this).siblings("[type='file']").val('');
      $(this).siblings('span.filename').remove();
      $(this).remove();
    });

  });

  loadMoreFeed();

  $('.feed-block').on('click', '.like-comment', function(){
    var type = $(this).data('type');
    var id = $(this).data('id');
    var text = $(this).data('like') == "Like" ? "Unlike" : "Like";
    $(this).text(text).data('like',text);
    $("#like-"+type+"-"+id)[0].click();
    return false;
  });

  $( '.dropdown' ).on( 'show.bs.dropdown', function() {
    $( this ).find( '.dropdown-menu' ).first().stop( true, true ).slideDown( 150 );
  } );
  $('.dropdown').on( 'hide.bs.dropdown', function(){
    $( this ).find( '.dropdown-menu' ).first().stop( true, true ).slideUp( 150 );
  } );

  $('.feed-block').on('click','.cancel-comment', function(e){
    $('.feed-item .feed-form').remove();
    $("[id^='edit_']").remove();
    $("[id^='comment-reply-btn']").show();
    return false;
  });

  $('.credits-link').click(function(){
    $('.credits-purchasing .credits-count').text($(this).data('credits'));
    $('#credits_count').val($(this).data('credits'));
    $('.credits-purchasing').fadeIn();
    $("html, body").animate({ scrollTop: $(".credits-purchasing").offset().top - 120 }, 500);
    return false;
  });

  $('.change-credits').click(function(){
    $("html, body").animate({ scrollTop: 0 }, 500);
    return false;
  });

  $('.update-cc').click(function(){
    $('#payment-user-info').removeClass('d-none')
        .append('<div class="form-group" id="payment-form"></div>');
    braintree.setup(clientToken, "dropin", {
      container: "payment-form",
      paypal: {
        button: {
          type: "checkout"
        }
      },
      onError: function(payload) {
      }
    });
  });

  $('.btn-disabled').click(function(e){
    e.preventDefault();
  });

  $('.users-block .more-users').click(function(){
    $(this).find('span').toggle()
    .closest('.release-users-block').toggleClass('c-collapsed');
  });

  $('.toggle-switcher').click(function(){
    var visible = $('.toggle-pair:visible');
    var hidden = $('.toggle-pair:hidden')
    visible.hide(100, function(){
     hidden.show(100);
    });
  });
});

var loadMoreFeed = function(){
  var win = $(window);
  var feedId = $('.feed-block').data('feedId');
  var feed, data_feed = $('.feed-block').data('feed');
  var masterfeed = $('.feed-block').data('masterfeed');

  win.off('scroll.pagination');

  if($('.feed-block').length > 0 && 
      ( 
        masterfeed || 
        (feedId > 0 && data_feed != "topic") 
      ) 
    ) {


    win.on('scroll.pagination', function(e) {
      if ($(document).height() - win.height() == win.scrollTop()) {
        $('#loading').show();
        win.off('scroll.pagination');


        switch (data_feed) {
          case 'user':
            feed = "user_aggregated";
            break;
          case 'timeline_aggregated':
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

          if (masterfeed) {
            feed = "masterfeed";
            feedId = 1;
          }
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
                loadMoreFeed();
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
