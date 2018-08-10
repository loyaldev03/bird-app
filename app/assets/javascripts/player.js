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
    ['.pp-volume-bar','.volume-bar-value','volume']
  ]
  dragBars(draggedBars);
});
