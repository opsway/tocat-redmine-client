class TocatRolesController < ApplicationController
  unloadable
  layout 'tocat_base'

  before_filter :require_admin
  before_filter :find_role, :only => [:edit, :update, :destroy]
  before_filter :find_permissions

  def set_role
    user = User.find(params[:user_id])
    role = TocatRole.find(params[:role])
    user.tocat_user_role.destroy if user.tocat_user_role.present?
    record = TocatUserRole.new(user: user, tocat_role:role, creator_id: User.current.id)
    if record.save
      render json: {}, status: 200
    else
      render json: {}, status: 406
    end
  end


  def index
    @roles = TocatRole.all
  end

  def new
    array = []
    TocatRole.permissions.each do |r|
      array << r.second.collect {|p| p.to_sym unless p.blank? }.compact.uniq
    end
    @role = TocatRole.new(params[:tocat_role] || {:permissions => array.flatten})
    @roles = TocatRole.all
  end

  def create
    @role = TocatRole.new(params[:tocat_role])
    if request.post? && @role.save
      # workflow copy
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      @roles = TocatRole.all
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    if request.put? and @role.update_attributes(params[:tocat_role])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @role.destroy
    redirect_to :action => 'index'
  rescue
    flash[:error] =  l(:error_can_not_remove_role)
    redirect_to :action => 'index'
  end

  def permissions
    @roles = TocatRole.sorted.all
    @permissions = Redmine::AccessControl.permissions.select { |p| !p.public? }
    if request.post?
      @roles.each do |role|
        role.permissions = params[:permissions][role.id.to_s]
        role.save
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    end
  end

  private

  def find_role
    @role = TocatRole.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_permissions
    params.permit!
    @permissions = TocatRole.permissions
  end

end
