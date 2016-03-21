var order_team = document.getElementById ('order_team');
var order_commission = document.getElementById ('order_commission');
order_team.onchange=function(){
    order_commission.value = ''
};
