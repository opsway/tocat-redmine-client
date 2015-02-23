class InvoicesController < ApplicationController
  unloadable

  before_filter :find_invoice, :except => [:new, :create, :index, :create_suborder]
  before_filter :check_for_setup
  layout 'tocat_base'
  helper :sort
  include SortHelper



  def new
  end


  def create
  end


  def update
  end


  def edit
  end


  def index
    sort_update %w(external_id total paid)

    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search_query] = params[:name] if params[:name].present?
    query_params[:paid] = params[:paid] if params[:paid].present?
    if params[:sort].present?
      query = []
      [*params[:sort]].each do |option|
        option.gsub!(':', '_')
        query << option
      end
      query_params[:sorted_by] = query.join(', ')
    end
    @invoices = TocatInvoice.all(params: query_params)
    @invoice_count = @invoices.http_response['X-total'].to_i
    @invoice_pages = Paginator.new @invoice_count, @invoices.http_response['X-Per-Page'].to_i, params['page']
  end


  def show
  end


  def set_paid
  end

  def set_unpaid
  end

  private

  def find_invoice
    @invoice = TocatInvoice.find(params[:id])
  end

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
