class InternalInvoicesController < TocatBaseController
  unloadable
  before_filter :check_action
  before_filter :find_request, only: [:edit, :update, :show, :destroy, :pay]
  def withdraw
    status, error = TransferRequest.withdraw params[:id]
    if status
      flash[:notice] = 'You sucessfully withdraw'
    else 
      flash[:notice] = 'Withdraw failed: ' + error
    end
    return redirect_back_or_default(action: 'my_tocat', controller: 'tocat')
  end

  def index
    params[:state] ||= 'new'
    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:source] = params[:source] if params[:source].present?
    query_params[:target] = params[:target] if params[:target].present?
    query_params[:state] = params[:state] if params[:state].present?

    @recipients = TransferRequest.new.available_recepients
    @balance_transfers = TransferRequest.all(params: query_params)
    @transfers_count = @balance_transfers.http_response['X-total'].to_i
    @transfers_pages = Paginator.new self, @transfers_count, @balance_transfers.http_response['X-Per-Page'].to_i, params['page']
  end

  def show
  end
  
  def new
    @transfer_request = TransferRequest.new
  end
  
  def pay
    begin
      @transfer_request.pay params[:transfer_request][:source_account_id]
      return redirect_back_or_default({:action => 'show', id: @transfer_request})
    rescue => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      return redirect_back_or_default({:action => 'show', id: @transfer_request.id})
    end
  end
  
  def destroy
    begin
      if @transfer_request.destroy
        respond_to do |format|
          flash[:notice] = l(:message_request_deletion_ok)
          format.html { redirect_back_or_default({:action => 'index'})}
        end
      else
        respond_to do |format|
          flash[:notice] = @transfer_request.errors
          format.html { redirect_back_or_default({:action => 'show', id: @transfer_request})}
        end
      end
    rescue => @e
      respond_to do |format|
        flash[:error] = JSON.parse(@e.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:action => 'show', id: @transfer_request})}
      end
    end
  end
  
  def create
    @transfer_request = TransferRequest.new(params[:transfer_request])

    begin
      if @transfer_request.save
        flash[:notice] = l(:notice_transfer_request_successful_created)
        return redirect_to({:action => 'index'})
      else
        flash[:error] = l(:notice_transfer_request_creation_fail)
        return redirect_to({:action => 'new'})
      end
    rescue => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      respond_to do |format|
        format.html { render :template => 'transfer_request/new' }
      end
    end
  end
    
  private
  
  def find_request
    @transfer_request = TransferRequest.find(params[:id])
  end

end
