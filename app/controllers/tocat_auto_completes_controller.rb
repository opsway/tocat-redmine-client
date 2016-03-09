class TocatAutoCompletesController < ApplicationController
  unloadable

  def orders
    @orders = []
    q = (params[:q] || params[:term]).to_s.strip
    if q.present?
      @orders = TocatOrder.auto_complete(q).to_a
      @orders.compact!
    end
    render :layout => false
  end
end
