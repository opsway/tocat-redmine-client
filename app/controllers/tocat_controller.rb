class TocatController < ApplicationController
  unloadable
  layout 'tocat_base'
  helper :sort
  include SortHelper
  helper :queries
  include QueriesHelper
  before_filter :check_for_setup
  before_filter :check_action

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
        flash[:notice] = payload
        format.html { redirect_back_or_default({:controller => 'issues', :action => 'show', id: issue.id })}
      end
    end
  end

  def update_resolver
    @issue = Issue.find(params[:issue_id])
    resolver = User.find(params[:resolver_id])
    status, errors = TocatTicket.update_resolver(@issue.tocat.id, resolver.tocat.id)
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
    @teams = TocatTeam.available_for_issue(@issue).collect{ |g| [g.id, g.name] }
    @orders = TocatOrder.all
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
      target = User.where(id:params[:user_id]).first
      if target.present? && check_permissions(target)
        @user = target
      else
        return render_403
      end
    else
      @user = User.current
    end
    begin
      @user_tocat = TocatUser.find(TocatUser.find_by_name(@user.name).id)
      @team_tocat = TocatTeam.find(@user_tocat.team.id)
      transactions = TocatTransaction.get_transactions_for_user(@user_tocat.id)
      @balance_transactions = []
      @income_transactions = []
      transactions.each do |t|
        t.type == 'balance' ?
          @balance_transactions << t :
          @income_transactions << t
      end
      transactions = TocatTransaction.get_transactions_for_team(@team_tocat.id)
      @team_balance_transactions = []
      @team_income_transactions = []
      transactions.each do |t|
        t.type == 'balance' ?
          @team_balance_transactions << t :
          @team_income_transactions << t
      end
      @accepted_tasks = TocatTicket.get_accepted_tasks(true, @user_tocat.id)
      @not_accepted_tasks = TocatTicket.get_accepted_tasks(false, @user_tocat.id)
      @not_accepted_balance = 0
      @not_accepted_tasks.each { |t| @not_accepted_balance += t.budget }
      @accepted_balance = 0
      @accepted_tasks.each { |t| @accepted_balance += t.budget }
    rescue Exception => e
      return render_404
    end
    respond_to do |format|
      format.html { render :template => 'tocat/my_tocat' }
    end
  end

  private

  def check_action
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
