class AccountsController < TocatBaseController
  before_filter :check_action
  before_filter :find_account, only: [:edit,:update,:show, :add_user, :remove_user] 
  def index
    query_params = {anyuser: true}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    if params[:account_type].present?
      query_params[:search] = "#{query_params[:search]} account_type == #{params[:account_type]}"
    end

    @accounts = Account.all(params: query_params)
    @accounts_count = @accounts.http_response['X-total'].to_i
    @accounts_pages = Paginator.new self, @accounts_count, @accounts.http_response['X-Per-Page'].to_i, params['page']
  end
  
  def show
  end
  
  def new 
    @account = Account.new
  end

  def add_user
    status, error = @account.add_access params[:user_id], params[:default]
    unless status
      flash[:error] = JSON.parse(error.response.body)['errors'].join(', ')
      return redirect_to :back
    end
    return redirect_to :back, notice: l(:notice_access_added)
  end
  
  def remove_user
    @account.delete_access params[:user_id]
    return redirect_to :back, notice: l(:notice_access_removed)
  end
  
  def create
    @account= Account.new(params[:account])
    if  @account.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    begin
      if @account.update_attributes(params[:account])
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'index'
      else
        render :action => 'edit'
      end
    rescue ActiveResource::ClientError => @e
      respond_to do |format|
        flash[:error] = JSON.parse(@e.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:action => 'edit', id: @account.id}) }
      end
    end
  end

  private
  def find_account
    @account = Account.find params[:id]
  end
end
