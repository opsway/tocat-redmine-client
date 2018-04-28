class TocatController < TocatBaseController
  unloadable
  helper :sort
  include SortHelper
  helper :queries
  include QueriesHelper
  before_filter :check_for_setup
  before_filter :check_action, except: [:request_review, :review_handler]

  def create_salary_checkin
    user = TocatUser.find(params[:user_id].to_i)
    status, messages = user.add_salary(params[:comment], params[:total])
    if status
      flash[:notice] = l(:notice_transaction_successful_created)
      respond_to do |format|
        format.html { redirect_back_or_default({ :controller => 'tocat', :action => 'my_tocat', user_id: params[:user_id]}) }
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(messages.response.body)['errors'].join(', ')
        format.html { render :action => 'new_salary_checkin' }
      end
    end
  end

  def new_salary_checkin
  end

  def new_correction
  end
  def create_correction
    user = TocatUser.find(params[:user_id].to_i)
    status, messages = user.add_correction(params[:comment], params[:total])
    if status
      flash[:notice] = l(:notice_transaction_successful_created)
      respond_to do |format|
        format.html { redirect_back_or_default({ :controller => 'tocat', :action => 'my_tocat', user_id: params[:user_id]}) }
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(messages.response.body)['errors'].join(', ')
        format.html { render :action => 'new_correction' }
      end
    end
  end


  def request_review
    toggle_review_requested
  end
  def review_handler
    toggle_review_requested
  end

  def toggle_review_requested
    issue = Issue.find(params[:issue_id])
    status, payload = issue.tocat.toggle_review_requested
    if status
      respond_to do |format|
        format.js { render :text => "OK", :status => 200 }
      end
    else
      respond_to do |format|
        format.js { render :text => "Fail", :status => 406 }
      end
    end
  end

  def toggle_accepted
    issue = Issue.find(params[:id])
    status, payload = issue.tocat.toggle_paid
    if status
      respond_to do |format|
        flash[:notice] = l(:message_issue_accepted)
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', id: issue.id })}
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(payload.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', id: issue.id })}
      end
    end
  end

  def set_expenses
    issue = Issue.find(params[:id])
    status, payload = issue.tocat.set_expenses
    if status
      respond_to do |format|
        flash[:notice] = l(:message_expense_accepted)
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', id: issue.id })}
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(payload.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', id: issue.id })}
      end
    end
  end

  def remove_expenses
    issue = Issue.find(params[:id])
    status, payload = issue.tocat.remove_expenses
    if status
      respond_to do |format|
        flash[:notice] = l(:message_remove_expense_accepted)
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', id: issue.id })}
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(payload.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', id: issue.id })}
      end
    end
  end

  def update_resolver
    @issue = Issue.find(params[:issue_id])
    resolver_id = params[:resolver_id]
    status, errors = TocatTicket.update_resolver(@issue.tocat.id, resolver_id)
    if status
      data = []
      data << render_to_string(:partial => 'issues/orders')
      data << render_to_string(:partial => 'issues/tocat_data')
      respond_to do |format|
        format.js {   render( :text => data, :status => :ok ) }
      end
    else
      render :json =>  errors.response.body, :status => :bad_request
    end
  end

  def budget_dialog
    @issue = Issue.find(params[:issue_id])
    if params[:order_id].present?
      order_ = TocatOrder.find(params[:order_id])
      order = {}
      order[:id] = order_.id
      order[:balance] = @issue.get_balance_for_order(order_.id)
      order[:free_budget] = order_.free_budget
      @order = OpenStruct.new(order)
    end
    @teams = TocatTeam.available_for_issue(@issue).collect { |g| [g.id, g.name] }
    @orders = TocatOrder.find(:all, params: {limit: 9999999})
    return render template: 'issues/budget_dialog'
    # see http://stackoverflow.com/questions/9025338/rails-upgrade-to-3-1-changing-ajax-handling-from-render-update-to-respond-t
  end

  def save_budget_dialog
    @issue = Issue.find(params[:issue_id])
    budgets = []
    status, payload = TocatTicket.get_budgets(@issue.tocat.id)
    return render :status => :bad_request unless status
    payload.each do |budget|
      if budget.id == params[:order_id].to_i
        budgets << { order_id:budget.id, budget:params[:budget] }
      else
        budgets << { order_id:budget.id, budget:budget.budget }
      end
    end
    unless payload.collect(&:id).include? params[:order_id].to_i
      budgets << { order_id:params[:order_id].to_i, budget:params[:budget].to_i }
    end
    status, errors = TocatTicket.set_budgets(@issue.tocat.id, budgets)
    if status
      data = []
      data << render_to_string(:partial => 'issues/orders')
      data << render_to_string(:partial => 'issues/tocat_data')
      respond_to do |format|
        format.js {   render( :text => data, :status => :ok ) }
      end
    else
      render :json =>  errors.response.body, :status => :bad_request
    end
  end

  def delete_budget
    @issue = Issue.find(params[:issue_id])
    budgets = []
    status, payload = TocatTicket.get_budgets(@issue.tocat.id)
    return render :status => :bad_request unless status
    payload.each do |budget|
      unless budget.id == params[:order_id].to_i
        budgets << { order_id:budget.id, budget:budget.budget }
      end
    end
    status, errors = TocatTicket.set_budgets(@issue.tocat.id, budgets)
    if status
      data = render_to_string :partial => 'issues/orders'
      render json: { :text => data }, :status => :ok
      # respond_to do |format|
        # format.js { render( :text => data, :status => :ok ) }
      # end
    else
      render :json =>  errors.response.body, :status => :bad_request
    end
  end

  def my_tocat
    begin
      if params[:user_id].present?
        @user_tocat = TocatUser.find(params[:user_id])

        if check_permissions(@user_tocat)
          @user = @user_tocat.redmine || @user_tocat
        else
          return render_403
        end
      else
        @user = User.current
        @user_tocat = @user.tocat
      end

      unless @user_tocat.coach? || @user_tocat.tocat_server_role == 'Manager'
        begin
          @team_tocat = TocatTeam.find(@user_tocat.tocat_team.id)

          @income_transactions =  TocatTransaction.find(:all, params:{user: @user_tocat.payroll_account.id, limit: 30, search: "created_at > #{3.months.ago.strftime('%Y-%m-%d')} account = payroll" })
          @balance_transactions = TocatTransaction.find(:all, params:{user: @user_tocat.balance_account.id, limit: 30, search: "account = balance" })
          @money_transactions = TocatTransaction.find(:all, params:{user: @user_tocat.money_account.id, limit: 30, search: "account = money" })

          @accepted_tasks = TocatTicket.get_accepted_tasks(true, @user_tocat.id)
          @not_accepted_tasks = TocatTicket.get_accepted_tasks(false, @user_tocat.id)
        rescue Exception => e
          Rails.logger.info "\e[31mException in Tocat. #{e.message}, #{e.backtrace.first}\e[0m"
          return render_404
        end
      end

      respond_to do |format|
        format.html { render :template => 'tocat/my_tocat' }
      end

    rescue ActiveResource::ResourceNotFound
      render_404
    end
  end

  def tocat_chart_data
    if params[:user_id].present?
      user_tocat = TocatUser.find(params[:user_id])
      target = User.find_by_login(user_tocat.login)
      return render_403 unless target.present? && check_permissions(target)
    else
      user_tocat = User.current.tocat
    end
    begin
      balance_chart = TocatBalanceChart.new(user_tocat, params[:period]).chart_data
    rescue Exception => e
      Rails.logger.info "\e[31mException in Tocat. #{e.message}, #{e.backtrace.first}\e[0m"
      return render_404
    end
    render json: balance_chart
  end
  def new_payment
    @users = TocatUser.find(:all, params: { limit: 99999 }).sort_by(&:name)
    @users_data = {}
    @users.collect { |t| @users_data[t.id] = t.income_account_state }
    @users_data = @users_data.to_json
  end
  def create_payment
    user = TocatUser.find(params[:user_id].to_i)
    status, messages = user.add_payment(params[:comment], params[:total])
    if status
      flash[:notice] = l(:notice_transaction_successful_created)
      respond_to do |format|
        format.html { redirect_back_or_default({ :controller => 'transactions', :action => 'index'}) }
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(messages.response.body)['errors'].join(', ')
        format.html { render :action => 'new_payment' }
      end
    end
  end



  private

  def check_permissions(target)
    return true if User.current.tocat_allowed_to?(:is_admin)
    return true if User.current.tocat_allowed_to?(:can_see_public_pages) && !(target.permissions.include?('has_protected_page'))
    false
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
