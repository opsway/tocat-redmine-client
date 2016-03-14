class TocatAutoCompletesController < ApplicationController
  unloadable

  def parent_orders
    @orders = []
    q = (params[:q] || params[:term]).to_s.strip
    child_id = params[:order_id].to_s.strip
    if q.present?
      @orders = TocatOrder.parent_auto_complete(q, child_id).to_a
      @orders.compact!
    end
    render :layout => false
  end
end
