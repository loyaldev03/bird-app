$(document).on('turbolinks:load', () => {
  $("body").on('click', '.jp-previous', function(){
    playPrevious();
  });

  $("body").on('click', '.jp-next', function(){
    playNext();
  });

  $("body").on('click', "[class^='play-']", function(e){
    e.preventDefault();
    var sourceType = $(this).data('sourceType');
    
    if (sourceType === 'release') {
      $("[class^='play-release-']").show().next('.jp-controls').css({'display': 'none'});
      $('#play-release-' + sourceType).hide().next('.jp-controls').css({'display': 'inline-flex'});
    }

    playButton(this);
  });

  updatePlayerState();
});
