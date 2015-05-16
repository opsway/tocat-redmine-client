class StatusController < ApplicationController
  unloadable
  layout 'tocat_base'
  before_filter :check_action

  def status
    resource = RestClient::Resource.new("#{RedmineTocatClient.settings[:host]}/status/selfcheck")
    @report = JSON.parse(resource.get)
  end

  private

  def check_action
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
  end
end
