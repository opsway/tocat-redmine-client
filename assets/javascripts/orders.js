function setTeamCommission(){
    var order_team = jQuery.noConflict()('#order_team');
    var order_commission = jQuery.noConflict()('#order_commission');
    var commission = order_team.data('commissions')[order_team.val()];
    order_commission.val(commission);
}

var teamSelect = jQuery.noConflict()('#order_team');
teamSelect.change(setTeamCommission);

check_zoho = function(){
  jQuery('#zoho').html($("<img src='http://i.stack.imgur.com/FhHRx.gif'></img>"));
  var url = jQuery('#zoho').data('src');
  jQuery('#dialog').html(jQuery("<img/>"));
  jQuery('#dialog img').on('load', function(){jQuery('#zoho').html('Check in ZohoReports')}).on('error', function(){jQuery('#zoho').html('Check in ZohoReports')}).attr('src', url);
  jQuery('#dialog').dialog();
  return false;
}