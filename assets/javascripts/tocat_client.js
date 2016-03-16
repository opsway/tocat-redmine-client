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
