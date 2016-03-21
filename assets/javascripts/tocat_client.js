if (typeof jQuery === 'undefined') {
  document.write(unescape('%3Cscript%20src%3D%22//ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js%22%3E%3C/script%3E'));
}
function observeParentOrderField(fieldId, url, options) {
    jQuery.noConflict()(document).ready(function() {
        jQuery.noConflict()('#'+fieldId).autocomplete(jQuery.noConflict().extend({
            source: url,
            minLength: 2,
            search: function(){jQuery.noConflict()('#'+fieldId).addClass('ajax-loading');},
            response: function(){jQuery.noConflict()('#'+fieldId).removeClass('ajax-loading');}
        }, options));
        jQuery.noConflict()('#'+fieldId).addClass('autocomplete');
    });
}
