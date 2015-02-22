class OrdersController < ApplicationController
  unloadable
  before_filter :find_order, :except => [:new, :create, :index]
  before_filter :find_groups, :except => [:index]
  before_filter :check_for_setup
  layout 'tocat_base'
  helper :sort
  include SortHelper

  def new
    @order = TocatOrder.new
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
        binding.pry
        flash[:notice] = @order.errors
        format.html { redirect_back_or_default({:action => 'show', id: @order})}
      end
    end
  end

  def create
    @order = TocatOrder.new(params[:order])
    if @order.save
      flash[:notice] = l(:notice_successful_created)
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
      flash[:notice] = l(:notice_successful_update)
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
    @orders = TocatOrder.all(params: query_params)
    @order_count = @orders.http_response['X-total'].to_i
    @order_pages = Paginator.new @order_count, @orders.http_response['X-Per-Page'].to_i, params['page']
  end

  def show
  end

  private

  def find_groups
    @groups = []
    Group.all.each { |g| @groups << g if g.builtin_type.nil? }
    @groups
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
