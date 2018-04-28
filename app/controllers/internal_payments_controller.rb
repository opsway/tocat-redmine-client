class InternalPaymentsController < TocatBaseController
  unloadable
  before_filter :check_action

  def index
    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:source] = params[:source] if params[:source].present?
    query_params[:target] = params[:target] if params[:target].present?

    @recipients = Account.for_select
    @balance_transfers = TocatBalanceTransfer.all(params: query_params)
    @transfers_count = @balance_transfers.http_response['X-total'].to_i
    @transfers_pages = Paginator.new self, @transfers_count, @balance_transfers.http_response['X-Per-Page'].to_i, params['page']
  end

  def show
    begin
      @balance_transfer = TocatBalanceTransfer.find(params[:id])
    rescue ActiveResource::ResourceNotFound
      render_404
    end
  end

  def create
    begin
      @balance_transfer = TocatBalanceTransfer.new(params[:tocat_balance_transfer])
      if @balance_transfer.save
        flash[:notice] = l(:notice_balance_transfer_successful_create)
        redirect_to :action => 'index'
      else
        render :action => 'new'
      end
    rescue ActiveResource::ClientError => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      @error = JSON.parse(e.response.body)['errors'].join(', ')
      render :action => 'new'
      logger.info e.message
    end
  end

  def new
    @balance_transfer = TocatBalanceTransfer.new(btype: 'base')
  end

  private
  def get_admin_name
    @central_office = TocatTeam.all.find{|t| t.id == t.parent_id}
    @tocat_central_office_admin = TocatUser.find(:all, params: {search: 'team="' + @central_office.name + '"'}).find{|u| u.tocat_server_role.name == 'Manager'}
  end
end
