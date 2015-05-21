class TransactionsController < ApplicationController
  unloadable
  before_filter :check_for_setup
  layout 'tocat_base'
  helper :sort
  include SortHelper
  before_filter :check_action

  def index
    sort_update %w(created_at comment total)

    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    if params[:owner].present?
      if params[:owner].split('_').first == 'group'
        query_params[:team] = params[:owner].split('_').second.to_i
      elsif params[:owner].split('_').first == 'user'
        query_params[:user] = params[:owner].split('_').second.to_i
      end
    end
    query_params[:search] = "#{query_params[:search]} account == #{params[:account_type]}" if params[:account_type].present?
    query_params[:sort] = params[:sort] if params[:sort].present?

    @transactions = TocatTransaction.all(params: query_params)
    @transactions_count = @transactions.http_response['X-total'].to_i
    @transactions_pages = Paginator.new self, @transactions_count, @transactions.http_response['X-Per-Page'].to_i, params['page']
    @owners = {
      Group: TocatTeam.all.collect { |r| [r.name, "group_#{r.id}"] },
      User: TocatUser.all.collect { |r| [r.name, "user_#{r.id}"] }
    }
  end

  private

  def check_action
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
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
