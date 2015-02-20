class TocatController < ApplicationController
  unloadable
  layout 'tocat_base'
  before_filter :check_for_setup

  def show_order
    @order = TocatOrder.find(params[:order_id])
    @issue = Issue.last
    respond_to do |format|
      format.html { render :template => 'tocat/orders/show_order' }
    end
  end

  def orders
    current_menu_item = :orders
    @orders = TocatOrder.all
    respond_to do |format|
      format.html { render :template => 'tocat/orders' }
    end
  end

  def invoices
    current_menu_item = :invoices
    @orders = TocatOrder.all
    binding.pry
    respond_to do |format|
      format.html { render :template => 'tocat/invoices' }
    end
  end

  def my_tocat
    @orders = TocatOrder.all
    respond_to do |format|
      format.html { render :template => 'tocat/my_tocat' }
    end
  end

  private

  def check_for_setup
    errors = false
    errors = true unless RedmineTocatClient.settings[:host].present?

    if errors
      respond_to do |format|
        format.html { render(:template => 'error', :layout => !request.xhr?) }
        format.any(:atom, :csv, :pdf) { render(:nothing => true) }
      end
    end
  end
end
