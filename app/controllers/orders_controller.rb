class OrdersController < ApplicationController
  unloadable
  before_filter :find_order, :except => [:new, :create, :index, :create_suborder]
  before_filter :find_groups, :except => [:index]
  before_filter :check_for_setup
  layout 'tocat_base'
  helper :sort
  include SortHelper

  def new
    @order = TocatOrder.new
    @order.name = params[:name] if params[:name].present?
    @order.description = params[:description] if params[:description].present?
    @order.allocatable_budget = params[:allocatable_budget] if params[:allocatable_budget].present?
    @order.invoiced_budget = params[:invoiced_budget] if params[:invoiced_budget].present?
    @order.team = params[:team] if params[:team].present?
    @order.parent_order = params[:split] if params[:split].present?
    @groups = TocatTeam.all
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
        flash[:notice] = JSON.parse(@e.response.body)['message']
        format.html { redirect_back_or_default({:action => 'show', id: @order})}
      end
    end
  end

  def create_suborder
    parent = TocatOrder.find(params[:order][:parent_order])
    query = params[:order]
    query[:team] = { id: params[:order][:team] }
    begin
      @order = TocatOrder.post("#{parent.id}/suborder", query)
    rescue => error
      flash[:error] = JSON.parse(error.response.body)['message']
      query[:split] = params[:order][:parent_order]
      respond_to do |format|
        format.html { redirect_to :action => 'new', params: query }
      end
      return
    end
    flash[:notice] = l(:notice_suborder_successful_created)
    respond_to do |format|
      format.html { redirect_back_or_default({:action => 'show', :id => @order}) }
      format.js do
        render :update do |page|
          page.replace_html 'order-form', :partial => 'tocat/orders/edit', :locals => {:order => @order}
        end
      end
    end
  end

  def create
    @order = TocatOrder.new(params[:order])
    if @order.save
      flash[:notice] = l(:notice_order_successful_created)
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

  def update
    if @order.update_attributes(params[:order])
      flash[:notice] = l(:notice_order_successful_update)
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
    @groups = TocatTeam.all
  end

  def index
    sort_update %w(name invoiced_budget allocatable_budget free_budget)

    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:search] = "#{query_params[:search]} paid == #{params[:paid]}" if params[:paid].present?
    query_params[:sort] = params[:sort] if params[:sort].present?

    @orders = TocatOrder.all(params: query_params)
    @order_count = @orders.http_response['X-total'].to_i
    @order_pages = Paginator.new self, @order_count, @orders.http_response['X-Per-Page'].to_i, params['page']
  end

  def show
    @groups = TocatTeam.all
    @parent = @order.parent
  end

  private

  def find_groups
    @groups = Group.all
  end

  def find_order
    @order = TocatOrder.find(params[:id])
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
