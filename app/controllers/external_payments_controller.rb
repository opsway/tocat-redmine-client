# -*- coding: utf-8 -*-
class ExternalPaymentsController < TocatBaseController
  unloadable
  before_filter :check_action
  before_filter :find_request, except: [:index,:create,:new,:salary_checkin, :pay_in_cash]
  around_filter :process_errors_and_render, only: [:approve, :cancel, :reject, :complete]
  def index
    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:source] = params[:source] if params[:source].present?
    query_params[:status] = params[:status].presence || PaymentRequest.min_status
    @payment_requests = PaymentRequest.all(params: query_params)
    @payment_count = @payment_requests.http_response['X-total'].to_i
    @payment_pages = Paginator.new self, @payment_count, @payment_requests.http_response['X-Per-Page'].to_i, params['page']
  end
  %w(approve cancel reject complete).each do |m|
    define_method m do
      @payment_request.send m
      flash[:notice] = l("payment_request_#{m}_success".to_sym)
      return redirect_to external_payment_path(@payment_request)
    end
  end
  
  def pay_in_cash
    @payment_request = PaymentRequest.new(currency: 'USD', special: true, salary_account_id: TocatUser.find(params[:user_id]).accounts.balance.id)
    @payment_request.total = TocatUser.find(params[:user_id]).balance_account_state.abs
    @payment_request.description = 'выплатить зарплату'
  end
  
  def salary_checkin
    @payment_request = PaymentRequest.new(currency: 'USD', special: true, salary_account_id: TocatUser.find(params[:user_id]).accounts.balance.id, bonus: true)
  end
  
  def new
    @payment_request = PaymentRequest.new
  end
  
  def show
  end
  
  def create
    begin
      @payment_request = PaymentRequest.new params[:payment_request]
      if @payment_request.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => 'index'
      else
        redirect_to :back
      end
    rescue ActiveResource::ClientError => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      @error = JSON.parse(e.response.body)['errors'].join(', ')
      redirect_to :back
      logger.info e.message
    end
  end

  def update
    begin
      if @payment_request.update_attributes(params[:payment_request])
        flash[:notice] = l(:notice_payment_request_successful_update)
        redirect_to :action => 'index'
      else
        render :action => 'new'
      end
    rescue ActiveResource::ClientError => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      @error = JSON.parse(e.response.body)['errors'].join(', ')
      redirect_to :back
      logger.info e.message
    end
  end

  def dispatch_my
  end
  def dispatch_post
    begin
      @payment_request.dispatch params[:email]
      return redirect_to :action => 'show'
    rescue ActiveResource::ClientError => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      @error = JSON.parse(e.response.body)['errors'].join(', ')
      render :action => 'show'
    end
  end
  private
  def find_request
    @payment_request = PaymentRequest.find params[:id]
  end
  def process_errors_and_render
    begin
      yield
    rescue ActiveResource::ClientError => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      @error = JSON.parse(e.response.body)['errors'].join(', ')
      return redirect_to external_payment_path(@payment_request)
      logger.info e.message
    end
  end
end
