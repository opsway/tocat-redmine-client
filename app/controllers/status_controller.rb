class StatusController < TocatBaseController
  unloadable
  before_filter :check_action

  def status
    params_ = {}
    if params[:checked].present?
      params_[:search] = "checked == #{params[:checked]}"
    else
      params_[:search] = "checked == false"
    end
    @messages = []
    response = JSON.parse(RestClient.get("#{RedmineTocatClient.settings[:host]}/status", TocatUser.headers.merge({:params => params_})))
    response['messages'].each do |r|
      @messages << OpenStruct.new(:id => r['id'], :alert => r['alert'], :checked => r['checked'])
    end
    @timestamp = Time.parse(response['timestamp']) if response['timestamp'].present?
  end

  def checked
    method = request.delete? ? :delete : :post
    RestClient.try(method, "#{RedmineTocatClient.settings[:host]}/status/#{params[:id]}/checked", TocatUser.headers)
    respond_to do |format|
      flash[:notice] = l(:message_checked_updated)
      format.html { redirect_back_or_default({:controller => 'status', :action => 'status', :params => {:checked => params[:checked]} })}
    end
  end
end
