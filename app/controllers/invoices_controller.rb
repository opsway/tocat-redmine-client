class InvoicesController < ApplicationController
  unloadable

  before_filter :find_invoice, :except => [:new, :create, :index]
  before_filter :check_for_setup
  layout 'tocat_base'
  helper :sort
  include SortHelper
  before_filter :check_action

  def deattach_order
    order = TocatOrder.find(params[:order_id].to_i)
    begin
      status, errors = order.delete_invoice
    rescue ActiveResource::ResourceNotFound
    end
    if status
      respond_to do |format|
        flash[:notice] = l(:notice_order_successful_deattached)
        format.html { redirect_back_or_default({:action => 'show', id: @invoice})}
      end
    else
      respond_to do |format|
        flash[:error] = JSON.parse(errors.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:action => 'show', id: @invoice})}
      end
    end
  end


  def new
    @invoice = TocatInvoice.new
    @order = TocatOrder.find(params[:order]) if params[:order].present?
  end

  def destroy
    begin
      if @invoice.destroy
        respond_to do |format|
          flash[:notice] = l(:message_invoice_deletion_ok)
          format.html { redirect_back_or_default({:action => 'index'})}
        end
      else
        respond_to do |format|
          flash[:notice] = @order.errors
          format.html { redirect_back_or_default({:action => 'show', id: @invoice})}
        end
      end
    rescue ActiveResource::ResourceInvalid => @e
      respond_to do |format|
        flash[:error] = JSON.parse(@e.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:action => 'show', id: @invoice})}
      end
    end
  end


  def create
    @invoice = TocatInvoice.new(params[:invoice])
    begin
      if @invoice.save
        flash[:notice] = l(:notice_invoice_successful_created)
        respond_to do |format|
          format.html { redirect_back_or_default({ :action => 'show', :id => @invoice}) }
          format.js do
            render :update do |page|
              page.replace_html 'invoice-form', :partial => 'tocat/invoices/edit', :locals => {:invoice => @invoice}
            end
          end
        end
      else
        @invoice_old = @invoice
        respond_to do |format|
          format.html { render :template => 'invoices/edit' }
        end
      end
    rescue => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      respond_to do |format|
        format.html { render :template => 'invoices/edit' }
      end
    end
  end

  def edit
  end

  def update
    if @invoice.update_attributes(params[:invoice])
      flash[:notice] = l(:notice_invoice_successful_update)
      respond_to do |format|
        format.html { redirect_back_or_default({:action => 'show', :id => @invoice}) }
        format.js do
          render :update do |page|
            page.replace_html 'inovice-form', :partial => 'tocat/invoices/edit', :locals => {:invoice => @invoice}
          end
        end
      end
    else
      @invoice_old = @invoice
      @invoice.reload
      respond_to do |format|
        format.html { render :template => 'invoices/edit' }
      end
    end
  end

  def index
    sort_update %w(external_id total paid)

    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:search] = "#{query_params[:search]} paid == #{params[:paid]}" if params[:paid].present?
    query_params[:sort] = params[:sort] if params[:sort].present?

    @invoices = TocatInvoice.all(params: query_params)
    @invoice_count = @invoices.http_response['X-total'].to_i
    @invoice_pages = Paginator.new self, @invoice_count, @invoices.http_response['X-Per-Page'].to_i, params['page']
  end


  def show
  end


  def set_paid
    status, payload = @invoice.set_paid
    if status
      respond_to do |format|
        flash[:notice] = l(:message_invoice_paid)
        format.html { redirect_back_or_default({ :action => 'show', id: @invoice })}
      end
    else
      respond_to do |format|
        flash[:error] = l(:message_invoice_paid_failed)
        format.html { redirect_back_or_default({ :action => 'show', id: @invoice })}
      end
    end
  end

  def set_unpaid
    status, payload = @invoice.remove_paid
    if status
      respond_to do |format|
        flash[:notice] = l(:message_invoice_paid)
        format.html { redirect_back_or_default({ :action => 'show', id: @invoice })}
      end
    else
      respond_to do |format|
        flash[:error] = l(:message_invoice_paid_failed)
        format.html { redirect_back_or_default({ :action => 'show', id: @invoice })}
      end
    end
  end

  private

  def check_action
    params.permit! if params.respond_to? :permit!
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
  end

  def find_invoice
    @invoice = TocatInvoice.find(params[:id])
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

end
