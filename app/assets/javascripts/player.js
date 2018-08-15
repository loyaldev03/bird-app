$(document).on('turbolinks:load', () => {
  $("body").on('click', '.jp-previous', function(){
    playPrevious();
  });

  $("body").on('click', '.jp-next', function(){
    playNext();
  });

  $("body").on('click', '.pp-previous', function(){
    playPrevious();
  });

  $("body").on('click', '.pp-next', function(){
    playNext();
  });

  $("body").on('click', "[class^='play-']", function(e){
    var sourceType = $(this).data('sourceType');
    var sourceId = $(this).data('sourceId');
    
    if (sourceType === 'release') {
      $("[class^='play-release-']").show().next('.jp-controls').css({'display': 'none'});
      $('.btn.play-release-' + sourceId).hide().next('.jp-controls').css({'display': 'inline-flex'});
    }

    playButton(this);
    return false;
  });

  updatePlayerState();

  var draggedBars = [
    ['.pp-volume-bar','.volume-bar-value','volume'],
    ['.pp-seek-bar','.pp-play-bar','progress']
  ]
  dragBars(draggedBars);

  timerAndLoadingForAudio(cpAudio);

  if ($('.playlist-player').length > 0 && $('.jp-audio .jp-play').data('trackId') ) {
    $.ajax({
      url: '/fill_bottom_player',
      dataType: 'script',
      data: { track_id: $('.jp-audio .jp-play').data('trackId') }
    });
  }
});
