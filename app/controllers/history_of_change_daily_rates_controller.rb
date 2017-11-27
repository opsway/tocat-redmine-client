class HistoryOfChangeDailyRatesController < TocatBaseController

  def index
    query_params = {}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:search] = "#{query_params[:search]} user == #{params[:user]}" if params[:user].present?

    @daily_rates = TocatDailyRateHistory.all(params: query_params)
    @daily_rates_count = @daily_rates.http_response['X-total'].to_i
    @daily_rates_pages = Paginator.new self, @daily_rates_count, @daily_rates.http_response['X-Per-Page'].to_i, params['page']
    @users = TocatUser.fetch_all_active_users
  end
end