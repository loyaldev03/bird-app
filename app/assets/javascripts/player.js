$(document).on('turbolinks:load', () => {
  $("body").on('click', '.jp-previous', function(){
    playPrevious();
  });

  $("body").on('click', '.jp-next', function(){
    playNext();
  });

  $("body").on('click', "[class^='play-']", function(e){
    e.preventDefault();
    playButton(this);
  });

  updatePlayerState();
});
