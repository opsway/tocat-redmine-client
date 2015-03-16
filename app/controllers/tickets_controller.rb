class TicketsController < ApplicationController
  unloadable
  layout 'tocat_base'
  helper :sort
  include SortHelper

  def index
    sort_update %w(name budget)

    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:search] = "#{query_params[:search]} paid == #{params[:paid]}" if params[:paid].present?
    query_params[:sort] = params[:sort] if params[:sort].present?

    @tasks = TocatTicket.all(params: query_params)
    @tasks_count = @tasks.http_response['X-total'].to_i
    @tasks_pages = Paginator.new self, @tasks_count, @tasks.http_response['X-Per-Page'].to_i, params['page']
  end

end
