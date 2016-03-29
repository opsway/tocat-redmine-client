function setTeamCommission(){
    var order_team = jQuery.noConflict()('#order_team');
    var order_commission = jQuery.noConflict()('#order_commission');
    var commission = order_team.data('commissions')[order_team.val()];
    order_commission.val(commission);
}

var teamSelect = jQuery.noConflict()('#order_team');
teamSelect.change(setTeamCommission);