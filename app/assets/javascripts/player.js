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
    e.preventDefault();
    var sourceType = $(this).data('sourceType');
    var sourceId = $(this).data('sourceId');
    
    if (sourceType === 'release') {
      $("[class^='play-release-']").show().next('.jp-controls').css({'display': 'none'});
      $('.btn.play-release-' + sourceId).hide().next('.jp-controls').css({'display': 'inline-flex'});
    }

    playButton(this);
  });

  updatePlayerState();

  var draggedBars = [
    ['.pp-volume-bar','.volume-bar-value','volume'],
    ['.pp-seek-bar','.pp-play-bar','progress']
  ]
  dragBars(draggedBars);

  timerAndLoadingForAudio(cpAudio);

  $('.pp-track').html($('.jp-details').data('trackTitle'));
  $('.pp-artist').html($('.jp-details').data('trackArtist'));
});
