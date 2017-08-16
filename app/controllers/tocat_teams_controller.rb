class TocatTeamsController < TocatBaseController
  unloadable

  #before_filter :require_admin
  before_filter :check_action
  before_filter :find_team, :only => [:edit, :update, :destroy, :makeactive]

  def index
    query_params = {anyteam: true}
    query_params[:limit] = params[:per_page] if params[:per_page].present?
    query_params[:page] = params[:page] if params[:page].present?

    @teams = TocatTeam.all(params: query_params)
    @teams_count = @teams.http_response['X-total'].to_i
    @teams_pages = Paginator.new self, @teams_count, @teams.http_response['X-Per-Page'].to_i, params['page']
    @real_teams = @teams
  end

  def new
    @team = TocatTeam.new
  end

  def create
    begin
      @team = TocatTeam.new(params[:tocat_team])
      unless @team.valid?
        @team.role = OpenStruct.new(id: @team.role)
        @team.team = OpenStruct.new(id: @team.team)
        return render :action => 'new'
      end
      if request.post? && @team.save
        # workflow copy
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => 'index'
      else
        @teams= TocatTeam.all
        render :action => 'new'
      end
    rescue ActiveResource::ClientError => e
      flash[:error] = JSON.parse(e.response.body)['errors'].join(', ')
      @error = JSON.parse(e.response.body)['errors'].join(', ')
      render :new
      logger.info e.message
    end
  end

  def edit
  end

  def update
    begin
      if @team.update_attributes(params[:tocat_team])
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'index'
      else
        render :action => 'edit'
      end
    rescue ActiveResource::ClientError => @e
      respond_to do |format|
        flash[:error] = JSON.parse(@e.response.body)['errors'].join(', ')
        format.html { redirect_back_or_default({:action => 'edit', id: @team.id}) }
      end
    end
  end

  def destroy
    @team.destroy
    redirect_to :action => 'index'
  rescue
    flash[:error] =  l(:error_can_not_deactivate_team)
    redirect_to :action => 'index'
  end
  def makeactive
    self.destroy
  end
  
  private

  def find_team
    @team = TocatTeam.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
