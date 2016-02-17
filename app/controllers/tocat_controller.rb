class TocatController < ApplicationController
  unloadable
  layout 'tocat_base'
  helper :sort
  include SortHelper
  helper :queries
  include QueriesHelper
  before_filter :check_for_setup
  before_filter :check_action, except: [:request_review, :review_handler]

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

  def new_payment
    @users = TocatUser.find(:all, params: { limit: 99999 }).sort_by!(&:name)
    @users_data = {}
    @users.collect { |t| @users_data[t.id] = t.income_account_state }
    @users_data = @users_data.to_json
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
      respond_to do |format|
        format.js {   render( :text => data, :status => :ok ) }
      end
    else
      render :json =>  errors.response.body, :status => :bad_request
    end
  end

  def my_tocat
    if params[:user_id].present? 
      @user_tocat = TocatUser.find(params[:user_id])
      target = User.find_by_login(@user_tocat.login) 
      if target.present? && check_permissions(target)
        @user = target
      else
        return render_403
      end
    else
      @user = User.current
      @user_tocat = @user.tocat
    end
    begin
      #@user_tocat = TocatUser.find(TocatUser.find_by_name(@user.name).id) #!!!
      @team_tocat = TocatTeam.find(@user_tocat.tocat_team.id)
      #@team_balance_transactions = TocatTransaction.find(:all, params:{team: @team_tocat.id, limit:9999999, search: "account = balance" })

      @team_income_transactions =  TocatTransaction.find(:all, params:{team: @team_tocat.id, limit:9999999, search: "created_at > #{1.year.ago.strftime('%Y-%m-%d')} account = payment" })

      @team_balance_income_year = @team_tocat.income_account_state - @team_income_transactions.sum{|t| t.total.to_f}

      @balance_transactions = TocatTransaction.find(:all, params:{user: @user_tocat.id, limit:9999999, search: "account = balance" })
      @accepted_tasks = TocatTicket.get_accepted_tasks(true, @user_tocat.id)
      @not_accepted_tasks = TocatTicket.get_accepted_tasks(false, @user_tocat.id)
      
      
      #removed if manager?
      @balance_chart = { month: { balance: [], forecast: [], zero_line: [], timeline: [], income_team: [] },
                        halfyear: { balance: [], forecast: [], zero_line: [], timeline: [], income_team: []  },
                        year: { balance: [], forecast: [], zero_line: [], timeline: [], income_team: [] } }
      balance_transactions_ = TocatTransaction.find(:all, params: { search: "accountable_type == User accountable_id == #{@user_tocat.id} created_at >= #{1.year.ago.strftime('%Y-%m-%d')} account = balance", limit: 9999999})
      accepted_not_paid_events = TocatTicket.events_for(@accepted_tasks.collect(&:task_id), "task.accepted_update")
      balance_with_tasks = balance =  @user_tocat.balance_account_state - balance_transactions_.sum { |r| r.total.to_i}

      week = (1.week.ago.to_date..Date.today)
      month = (1.month.ago.to_date..Date.today)
      halfyear = (6.months.ago.to_date..Date.today)
      year = (1.year.ago.to_date..Date.today)
      accepted_not_paid_events = accepted_not_paid_events.select{ |r| r.parameters['new'] == true }.uniq(&:id)
      events_count = accepted_not_paid_events.count
      (1.year.ago.to_date..Date.today).each do |date|
        events_sum = accepted_not_paid_events.select{ |r| r.created_at.to_date == date }.sum { |r| r.parameters["balance"].to_i}
        transactions_sum =  @balance_transactions.select{ |r| r.date.to_date == date}.sum { |r| r.total.to_i }
        
        team_transactions_sum = @team_income_transactions.select{|r| r.date.to_date == date}.sum{|r| r.total.to_f}
        @team_balance_income_year += team_transactions_sum.round(2)

        balance_with_transactions = (balance += transactions_sum).round(2)
        forecast_balance = (balance_with_tasks += (events_sum + transactions_sum)).round(2)

        if month.include?(date)
          @balance_chart[:month][:balance] << balance_with_transactions
          @balance_chart[:month][:income_team] << @team_balance_income_year
          

          if @user_tocat.tocat_server_role.name == 'Manager'
            @balance_chart[:month][:forecast] << balance_with_transactions
          else
            @balance_chart[:month][:forecast] << forecast_balance
          end
          @balance_chart[:month][:zero_line] << 0
          @balance_chart[:month][:timeline] << date
        end
        if halfyear.include?(date)
          @balance_chart[:halfyear][:balance] << balance_with_transactions
          @balance_chart[:halfyear][:income_team] << @team_balance_income_year

          if @user_tocat.tocat_server_role.name == 'Manager'
            @balance_chart[:halfyear][:forecast] << balance_with_transactions
          else
            @balance_chart[:halfyear][:forecast] << forecast_balance
          end
          @balance_chart[:halfyear][:zero_line] << 0
          @balance_chart[:halfyear][:timeline] << date
        end

        @balance_chart[:year][:balance] << balance_with_transactions
        @balance_chart[:year][:income_team] << @team_balance_income_year
        if @user_tocat.tocat_server_role.name == 'Manager'
          @balance_chart[:year][:forecast] << balance_with_transactions
        else
          @balance_chart[:year][:forecast] << forecast_balance
        end
        @balance_chart[:year][:zero_line] << 0
        @balance_chart[:year][:timeline] << date
      end
    rescue Exception => e
      Rails.logger.info "\e[31mException in Tocat. #{e.message}, #{e.backtrace.first}\e[0m"
      return render_404
    end
    respond_to do |format|
      format.html { render :template => 'tocat/my_tocat' }
    end
  end

  private

  def check_action
    params.permit!
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
  end

  def check_permissions(target)
    return true if User.current.tocat_allowed_to?(:is_admin)
    return true if User.current.tocat_allowed_to?(:can_see_public_pages) && !(target.tocat_allowed_to?(:has_protected_page))
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
