class TocatController < ApplicationController
  unloadable
  before_filter :check_for_setup

  def index
    orders = TocatOrder.all
    invoices = TocatInvoices.all
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
