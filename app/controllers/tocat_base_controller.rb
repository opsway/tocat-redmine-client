class TocatBaseController < ApplicationController
  layout 'tocat_base'
  rescue_from ActiveResource::UnauthorizedAccess, with: :deny_access
  private
  def check_action
    params.permit! if params.respond_to? :permit!
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
  end
end
