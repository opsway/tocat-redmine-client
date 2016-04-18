class BalanceTransfersController < ApplicationController
  unloadable
  layout 'tocat_base'
  before_filter :check_action

  def index
    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:source] = params[:source] if params[:source].present?
    query_params[:target] = params[:target] if params[:target].present?

    @recipients = TocatBalanceTransfer.new.available_recepients
    @balance_transfers = TocatBalanceTransfer.all(params: query_params)
    @transfers_count = @balance_transfers.http_response['X-total'].to_i
    @transfers_pages = Paginator.new self, @transfers_count, @balance_transfers.http_response['X-Per-Page'].to_i, params['page']
  end
  
  def show
    @balance_transfer = TocatBalanceTransfer.find(params[:id])
    p @balance_transfer.attributes
  end
  
  def create
    @balance_transfer = TocatBalanceTransfer.new(params[:tocat_balance_transfer])
    if @balance_transfer.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def new
    @balance_transfer = TocatBalanceTransfer.new
  end
  
  private

  def check_action
    params.permit! if params.respond_to? :permit!
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
  end
end
