class OrdersController < ApplicationController
  unloadable
  before_filter :find_order, :except => [:new, :create, :index, :create_suborder]
  before_filter :find_groups, :except => [:index]
  before_filter :check_for_setup
  layout 'tocat_base'
  helper :sort
  include SortHelper
  before_filter :check_action
  before_filter :load_available_parents, only: [:show, :edit]




  def new
    @order = TocatOrder.build
    @order.name = params[:name] if params[:name].present?
    @order.description = params[:description] if params[:description].present?
    @order.allocatable_budget = params[:allocatable_budget] if params[:allocatable_budget].present?
    @order.invoiced_budget = params[:invoiced_budget] if params[:invoiced_budget].present?
    @order.team = params[:team] if params[:team].present?
    @order.parent_order = params[:split] if params[:split].present?
    @parent_order = @order.load_parent_order
    @order.invoiced_budget = @parent_order.free_budget if @parent_order
  end

  def destroy
    begin
      if @order.destroy
        respond_to do |format|
          flash[:notice] = l(:message_order_deletion_ok)
          format.html { redirect_back_or_default({:action => 'index'})}
        end
      else
        respond_to do |format|
          flash[:notice] = @order.errors
          format.html { redirect_back_or_default({:action => 'show', id: @order})}
        end
      end
    rescue ActiveResource::ResourceInvalid => @e
      respond_to do |format|
        flash[:error] = JSON.parse(@e.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:action => 'show', id: @order})}
      end
    end
  end

  def create_suborder
    parent = TocatOrder.find(params[:order][:parent_order])
    query = params[:order].clone
    query[:team] = { id: params[:order][:team] }
    status, error, response = parent.set_suborder(query)
    if status
      flash[:notice] = l(:notice_suborder_successful_created)
      respond_to do |format|
        format.html { redirect_back_or_default({ :action => 'show', :id => response['id'].to_i }) }
        format.js do
          render :update do |page|
            page.replace_html 'order-form', :partial => 'tocat/orders/edit', :locals => {:order => @order}
          end
        end
      end
    else
      flash[:error] = JSON.parse(error.response.body)['errors'].join(', ')
      query[:split] = params[:order][:parent_order]
      respond_to do |format|
        @order = TocatOrder.new(params[:order])
        format.html { render :template => 'orders/new' }
      end
      return
    end
  end

  def create
    @order = TocatOrder.new(params[:order])
    begin
      if @order.save
        process_commission
        respond_to do |format|
          if params[:redirect_to].present?
            array = params[:redirect_to].split(':')
            if array.length == 4
              status, payload = TocatTicket.get_budgets(array.third.to_i)
              budgets = []
              payload.each do |budget|
                budgets << { order_id:budget.id, budget:budget.budget }
              end
              budgets << {order_id: @order.id, budget:params[:budget].to_i}
              status, errors = TocatTicket.set_budgets(array.third.to_i, budgets)
              if status
                flash[:notice] = l(:notice_order_successful_created)
                redirect_to({:controller => array.first, :action => array.second, :id => array.fourth.to_i})
                return
              else
                flash[:error] = l(:notice_order_creation_fail)
                redirect_to({:controller => array.first, :action => array.second, :id => array.fourth.to_i})
                return
              end
            end
          else
            format.html { redirect_back_or_default({:action => 'show', :id => @order}) }
            format.js do
              render :update do |page|
                page.replace_html 'order-form', :partial => 'tocat/orders/edit', :locals => {:order => @order}
              end
            end
          end
        end
      else
        @order_old = @order
        respond_to do |format|
          format.html { render :template => 'orders/edit' }
        end
      end
    rescue => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      respond_to do |format|
        format.html { render :template => 'orders/edit' }
      end
    end
  end

  def update
    if @order.update_attributes(params[:order])
      flash[:notice] = l(:notice_order_successful_update)
      process_commission
      respond_to do |format|
        format.html { redirect_back_or_default({:action => 'show', :id => @order}) }
        format.js do
          render :update do |page|
            page.replace_html 'order-form', :partial => 'tocat/orders/edit', :locals => {:order => @order}
          end
        end
      end
    else
      @order_old = @order
      @order.reload
      respond_to do |format|
        format.html { render :template => 'orders/edit' }
      end
    end
  end

  def edit
  end

  def index
    sort_update %w(name invoiced_budget allocatable_budget free_budget)

    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:search] = "#{query_params[:search]} paid == #{params[:paid]}" if params[:paid].present?
    query_params[:search] = "#{query_params[:search]} completed == #{params[:completed]}" if params[:completed].present?
    query_params[:search] = "#{query_params[:search]} team == #{params[:team]}" if params[:team].present?
    query_params[:search] = "#{query_params[:search]} internal_order == #{params[:internal_order]}" if params[:internal_order].present?
    if params[:suborder].present?
      params[:suborder].to_i == 1 ?
        query_params[:search] = "#{query_params[:search]} set? parent_id" :
        query_params[:search] = "#{query_params[:search]} null? parent_id"
    end
    if params[:invoiced].present?
      params[:invoiced].to_i == 1 ?
        query_params[:search] = "#{query_params[:search]} set? invoice_id" :
        query_params[:search] = "#{query_params[:search]} null? invoice_id"
    end
    query_params[:sort] = params[:sort] if params[:sort].present?

    @orders = TocatOrder.all(params: query_params)
    @order_count = @orders.http_response['X-total'].to_i
    @order_pages = Paginator.new self, @order_count, @orders.http_response['X-Per-Page'].to_i, params['page']
    @teams = TocatTeam.all.sort_by(&:name)
  end

  def show
    @parent = @order.parent
  end

  def set_invoice
    begin
      status, errors = @order.set_invoice(params[:invoice_id].to_i)
    rescue ActiveResource::ResourceNotFound
    end
    if status
      data = []
      data << render_to_string(:partial => 'orders/invoices')
      respond_to do |format|
        format.js {   render( :text => data, :status => :ok ) }
      end
    else
      render :json =>  JSON.parse(errors.response.body)['errors'].join(', '), :status => :bad_request
    end
  end

  def commission
    begin
      status, errors = @order.set_commission(params[:tocat_order][:commission].to_i)
      errors
    rescue ActiveResource::ResourceNotFound
    end
    if status
      flash[:notice] = l(:message_order_commission)
    else
      flash[:error] = JSON.parse(errors.response.body)['errors'].join(', ')
    end
    respond_to do |format|
      format.html { redirect_back_or_default({ :action => 'show', id: @order })}
    end
  end

  def toggle_complete
    toggle_completed
  end
  def toggle_uncomplete
    toggle_completed
  end

  def toggle_completed
    status, payload = @order.toggle_campleted
    if status
      respond_to do |format|
        flash[:notice] = l(:message_order_completed)
        format.html { redirect_back_or_default({ :action => 'show', id: @order })}
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(payload.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({ :action => 'show', id: @order })}
      end
    end
  end

  def delete_invoice
    begin
      status, errors = @order.delete_invoice
    rescue ActiveResource::ResourceNotFound
    end
    if status
      respond_to do |format|
        flash[:notice] = l(:notice_invoice_successful_deattached)
        format.html { redirect_back_or_default({:action => 'show', id: @order})}
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(errors.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:action => 'show', id: @order})}
      end
    end
  end

  def invoices
    @invoices = TocatInvoice.find(:all, params: { search: "paid = 0" })
    return render template: 'orders/invoice_dialog'
  end
  
  def set_internal
    status, payload = @order.set_internal
    if status
      respond_to do |format|
        flash[:notice] = l(:message_order_internal)
        format.html { redirect_back_or_default({ :action => 'show', id: @order })}
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(payload.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({ :action => 'show', id: @order })}
      end
    end
  end
  
  def remove_internal
    status, payload = @order.remove_internal
    if status
      respond_to do |format|
        flash[:notice] = l(:message_order_noninternal)
        format.html { redirect_back_or_default({ :action => 'show', id: @order })}
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(payload.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({ :action => 'show', id: @order })}
      end
    end
  end

  private

  def check_action
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
  end

  def find_groups
    @groups = TocatTeam.all.sort { |lhs, rhs| lhs.name.downcase <=> rhs.name.downcase }
  rescue ActiveResource::ResourceNotFound
    render_404
  end

  def find_order
    @order = TocatOrder.find(params[:id])
  rescue ActiveResource::ResourceNotFound
    render_404
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

  def process_commission
    if params[:order][:commission].present? && User.current.tocat_allowed_to?(:update_commission)
      begin
        status, errors = @order.set_commission(params[:order][:commission].to_i)
      rescue ActiveResource::ResourceNotFound
      end
      unless status
        flash[:error] = JSON.parse(errors.response.body)['errors'].join(', ')
      end
    end
  end

  def load_available_parents
    potential_parents = TocatOrder.available_parents(@order.id)
    @available_parents = []
    @available_parents << ['Select new parent order', 0] if !@order.parent_id && potential_parents.any?
    @available_parents << ['You can not change parent order', 0] unless @order.parent_id || potential_parents.any?
    @available_parents += potential_parents.map { |o| [o.name, o.id] }
  end
end
