class TocatUsersController < ApplicationController
  unloadable
  layout 'tocat_base'

  #before_filter :require_admin
  before_filter :check_action
  before_filter :find_user, :only => [:edit, :update, :destroy, :makeactive]

  def index
    query_params = {anyuser: true}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?

    @users = TocatUser.all(params: query_params)
    @users_count = @users.http_response['X-total'].to_i
    @users_pages = Paginator.new self, @users_count, @users.http_response['X-Per-Page'].to_i, params['page']
    @real_users = User.where(login: @users.map(&:login))
  end

  def new
    @user = TocatUser.new
  end

  def create
    @user= TocatUser.new(params[:tocat_user])
    if request.post? && @user.save
      # workflow copy
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      @users= TocatUser.all
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    if request.put? and @user.update_attributes(params[:tocat_user])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @user.destroy
    redirect_to :action => 'index'
  rescue
    flash[:error] =  l(:error_can_not_remove_user)
    redirect_to :action => 'index'
  end
  def makeactive
    self.destroy
  end

  private

  def find_user
    @user = TocatUser.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_action
    p '!'
    p '!'
    p request.env['PATH_INFO']
    p request.env['REQUEST_METHOD']
    p Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym})
    p '!'
    p '!'
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
  end

end
