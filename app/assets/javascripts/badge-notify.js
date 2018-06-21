$(document).on('turbolinks:load', function() {
  $.get('/badge-notify')
    .done(function(result){
      result['badges'].forEach(function(badge){
        $('#badge' + badge + 'Modal').modal();
      });
    });
});