class TicketsController < ApplicationController
  unloadable
  layout 'tocat_base'
  before_filter :check_action


  def index
    query_params = {}
    query = {}
    query_params[:limit] = 9999999
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:search] = "#{query_params[:search]} paid == #{params[:paid]}" if params[:paid].present?
    query_params[:search] = "#{query_params[:search]} accepted == #{params[:accepted]}" if params[:accepted].present?
    query_params[:search] = "#{query_params[:search]} review_requested == #{params[:review]}" if params[:review].present?
    if params[:resolver].present?
      if params[:resolver] === 'false' || params[:resolver] === 'true'
        params[:resolver] == 'true' ?
          query_params[:search] = "#{query_params[:search]} set? resolver" :
          query_params[:search] = "#{query_params[:search]} null? resolver"
      else
        query_params[:search] = "#{query_params[:search]} resolver == #{params[:resolver]}"
      end
    end
    if params[:budget_val].present?
      op = params[:budget_op]
      val = params[:budget_val]
      query_params[:search] = "#{query_params[:search]} budget #{op} #{val}"
    end
    @resolvers = TocatUser.find(:all, params: { limit: 100 }).sort_by(&:name)
    @budget_op = [['<', '<'], ['>', '>'], ['=', '='], ['<=', '<='], ['>=', '>=']]
    @projects = Project.all.sort_by(&:name)
    @states = IssueStatus.all

    if params[:project].present?
      query[:project_id] = params[:project]
    end

    if params[:status].present?
      query[:status_id] = params[:status]
    end

    if params[:statuses].present?
      query[:status_id] = params[:statuses].split(',')
    end

    @limit = per_page_option
    @offset = params[:page]

    if (params[:paid].present? || params[:accepted].present? || params[:resolver].present? || params[:budget].present?  || params[:review].present?) &&
       (params[:project].present? || params[:status].present? || params[:statuses].present?)
      tasks = TocatTicket.all(params: query_params)
      tasks = tasks.each_with_object({}){ |c,h| h[c.internal_id.to_i] = { id:c.id, accepted: c.accepted, paid:c.paid, budget:c.budget, resolver:c.get_resolver, review_requested: c.review_requested } }
      issues = Issue.joins(:project).joins(:status).where(query)
      @issues = []
      issues.each do |issue|
        task = tasks[issue.id]
        next unless task.present?
        @issues << OpenStruct.new(
                    id: issue.id,
                    project: issue.project,
                    status: issue.status,
                    subject: issue.subject,
                    review: task[:review_requested],
                    budget: task[:budget],
                    resolver: task[:resolver],
                    accepted: task[:accepted],
                    paid: task[:paid]
                  )
      end
      @issue_count = @issues.count
      @limit = per_page_option
      offset_start = (@limit * (@offset.to_i - 1))
      offset_start = 0 if offset_start < 0
      @issues = @issues[offset_start..((@limit * @offset.to_i) + @limit)]
    elsif params[:project].present? || params[:status].present?
      @limit = per_page_option
      @issue_count = Issue.where(query).count
      issues = Issue.joins(:project).joins(:status).where(query).order('created_on desc').limit(@limit).offset(@offset.to_i * @limit.to_i)
      @issues = []
      tasks = TocatTicket.all(params: query_params)
      tasks = tasks.each_with_object({}){ |c,h| h[c.internal_id.to_i] = { id:c.id, accepted: c.accepted, paid:c.paid, budget:c.budget, resolver:c.get_resolver, review_requested: c.review_requested } }
      query_params[:limit] = 999999999
      issues.each do |issue|
        task = tasks[issue.id]
        task = {} unless task.present?
        @issues << OpenStruct.new(
                    id: issue.id,
                    project: issue.project,
                    status: issue.status,
                    subject: issue.subject,
                    review: task[:review_requested],
                    budget: task[:budget],
                    resolver: task[:resolver],
                    accepted: task[:accepted],
                    paid: task[:paid]
                  )
      end
    else
      query_params[:limit] = @limit
      query_params[:page] = params[:page] if params[:page].present?
      tasks = TocatTicket.all(params: query_params)
      @limit = tasks.http_response['X-Per-Page'].to_i
      @issue_count = tasks.http_response['X-total'].to_i
      issues = Issue.joins(:project).joins(:status).where(id: tasks.collect(&:internal_id))
      tasks = tasks.each_with_object({}){ |c,h| h[c.internal_id.to_i] = { id:c.id, accepted: c.accepted, paid:c.paid, budget:c.budget, resolver:c.get_resolver, review_requested: c.review_requested } }
      @issues = []
      issues.each do |issue|
        task = tasks[issue.id]
        next unless task.present?
        @issues << OpenStruct.new(
                    id: issue.id,
                    project: issue.project,
                    status: issue.status,
                    subject: issue.subject,
                    review: task[:review_requested],
                    budget: task[:budget],
                    resolver: task[:resolver],
                    accepted: task[:accepted],
                    paid: task[:paid]
                  )
      end
    end
    @issue_pages = Paginator.new self, @issue_count, @limit, params['page']
  end

  private

  def check_action
    params.permit! if params.respond_to? :permit!
    render_403 unless TocatRole.check_path(Rails.application.routes.recognize_path(request.env['PATH_INFO'], {:method => request.env['REQUEST_METHOD'].to_sym}))
  end
end
