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
    query_params[:created_by] = params[:created_by] if params[:created_by].present?
    query_params[:status] = params[:status].presence || PaymentRequest.min_status
    @payment_requests = PaymentRequest.all(params: query_params)
    @payment_count = @payment_requests.http_response['X-total'].to_i
    @payment_pages = Paginator.new self, @payment_count, @payment_requests.http_response['X-Per-Page'].to_i, params['page']
  end
  %w(cancel complete).each do |m|
    define_method m do
      @payment_request.send m
      flash[:notice] = l("payment_request_#{m}_success".to_sym)
      return redirect_to external_payment_path(@payment_request)
    end
  end

  def new
    @payment_request = PaymentRequest.new
    #@payment_request.description = "Please describe: &#13;&#10; - receiving party (First Name/Last Name) &#13;&#10; - method of payment (Credit Card, Payoneer, etc) &#13;&#10; - details of payment (for example, credit card number); &#13;&#10; any other comments that can help accounting unit to process payment correctly".html_safe
  end

  def show
  end

  def create
    begin
      prepare_base64_file_params

      @payment_request = PaymentRequest.new params[:payment_request]
      if @payment_request.save
        flash[:notice] = l(:notice_payment_request_successful_create)
        redirect_to :action => 'index'
      else
        render :new
      end
    rescue ActiveResource::ClientError => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      @error = JSON.parse(e.response.body)['errors'].join(', ')
      render :new
      logger.info e.message
    end
  end

  def update
    begin
      prepare_base64_file_params
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

  private

  def find_request
    begin
      @payment_request = PaymentRequest.find params[:id]
    rescue ActiveResource::ResourceNotFound
      render_404
    end
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

  def prepare_base64_file_params
    if params[:payment_request].present? && params[:payment_request][:file].present?
      file = params[:payment_request][:file]
      filename = File.basename(file.path)
      content_type = MIME::Types.type_for(filename).first.content_type
      base64_image = Base64.encode64(File.read(file.path))
      params[:payment_request][:file] = "data:#{content_type};base64,#{base64_image}"
      params[:payment_request][:file_name] = file.original_filename
    end
  end
end
