// Re-apply alternating colors to stay correct after hiding/showing rows
function fixRowColors() {
  $('tr:not(.hidden)').each(function(index, element) {
    newClass = (index % 2 == 0 ? 'even' : 'odd')
    $(element).removeClass('odd even').addClass(newClass);
  })
}

$(document).ready(function() {
  var mountPoint = $('html').data().mountPoint;
  $('#select-all').change(function(e) {
    $('.export-checkbox').prop('checked', $(e.currentTarget).is(':checked'));
  });

  $('.result-row').each(function(index, element) {
    var id = $(this).attr('id')

    // Check the actual content of each syllabus and hide if empty
    $.ajax({ url: mountPoint + '/view/' + id }).done(function(data) {
      if (data == 'Syllabus missing or empty') {
        $(element).find('.view-link').html("Missing or empty");
        $(element).find('input[type=checkbox]').prop('disabled', true);
        $(element).addClass('missing')

        if ($('#hide-missing').prop('checked')) {
          $(element).addClass('hidden').hide();;
          fixRowColors();
        }

        if (index >= (parseInt($('#result-count').html()) - 1)) {
          $('#loading').fadeTo(1000, 0);
        }
      }
    })
  })

  // Checkbox option to toggle results with empty syllabi. Hidden by default
  $('#hide-missing').change(function(e) {
    if ($(e.currentTarget).is(':checked')) {
      $('.missing').addClass('hidden').hide();
      fixRowColors();
    } else {
      $('.missing').removeClass('hidden').show();
      fixRowColors();
    }
  });
});
