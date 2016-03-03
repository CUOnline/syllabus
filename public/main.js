$(document).ready(function() {
  $('#select-all').change(function(e) {
    $('.export-checkbox').prop('checked', $(e.currentTarget).is(':checked'));
  });
});
