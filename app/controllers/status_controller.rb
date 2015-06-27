class StatusController < ApplicationController
  unloadable
  layout 'tocat_base'
  before_filter :check_action

  def status
    params_ = {}
    params_[:search] = "checked == #{params[:checked]}" if params[:checked].present?
    @messages = []
    response = JSON.parse(RestClient.get("#{RedmineTocatClient.settings[:host]}/status", {:params => params_}))
    response['messages'].each do |r|
      @messages << OpenStruct.new(:id => r['id'], :alert => r['alert'], :checked => r['checked'])
    end
    @timestamp = response['timestamp']
  end

  def checked
    method = request.delete? ? :delete : :post
    RestClient.try(method, "#{RedmineTocatClient.settings[:host]}/status/#{params[:id]}/checked", {})
    respond_to do |format|
      flash[:notice] = l(:message_checked_updated)
      format.html { redirect_back_or_default({:controller => 'status', :action => 'status', :params => {:checked => params[:checked]} })}
    end
  end

  private

  def check_action
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
  end
end
