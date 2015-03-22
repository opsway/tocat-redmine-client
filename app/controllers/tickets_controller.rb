class TicketsController < ApplicationController
  unloadable
  layout 'tocat_base'

  def index
    query_params = {}
    query = {}
    query_params[:limit] = 100000
    query_params[:search] = params[:search] if params[:search].present?
    query_params[:search] = "#{query_params[:search]} paid == #{params[:paid]}" if params[:paid].present?
    query_params[:search] = "#{query_params[:search]} accepted == #{params[:accepted]}" if params[:accepted].present?
    query_params[:search] = "#{query_params[:search]} resolver == \"#{params[:resolver]}\"" if params[:resolver].present?

    # if params[:budget_val].present?
    #   op = params[:budget_op]
    #   val = params[:budget_val]
    #   query_params[:search] = "#{query_params[:search]} budget #{op} #{val}"
    # end

    if params[:project].present?
      query[:project_id] = params[:project]
    end
    if params[:status].present?
      query[:status_id] = params[:status]
    end
    unless params[:project].present? || params[:status].present? || params[:paid].present? || params[:accepted].present? || params[:resolver].present?
      query[:created_on] = Time.zone.now.all_week
    end
    @tickets = {}
    @issues = Issue.where(query).limit(1000).order('id desc')
    unless @issues.empty?
      query_params[:search] = "#{query_params[:search]} #{@issues.collect(&:id).join(' OR ')}"
      TocatTicket.find(:all, params: query_params).each do |ticket|
        @tickets[ticket.external_id] = {
          budget: ticket.get_budget,
          paid: ticket.get_paid,
          accepted: ticket.get_accepted,
          resolver: ticket.get_resolver
        }
      end
    end
    @resolvers = TocatUser.find(:all, params: { limit: 100 })
    @budget_op = [['<', '<'], ['>', '>'], ['=', '='], ['<=', '<='], ['>=', '>=']]
    @projects = Project.all
    @states = IssueStatus.all
  end
end
