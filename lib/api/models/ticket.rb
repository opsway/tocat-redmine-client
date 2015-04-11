class TocatTicket < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'tasks'
  self.element_name = 'task'
  add_response_method :http_response


  class << self
    def element_path(id, prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{element_name}/#{URI.parser.escape id.to_s}#{query_string(query_options)}"
    end

    def collection_path(prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
    end
  end

  def toggle_paid
    unless accepted
      begin
        connection.post("#{self.class.prefix}/task/#{id}/accept")
      rescue => error
        # TODO add logger
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete("#{self.class.prefix}/task/#{id}/accept")
      rescue => error
        # TODO add logger
        return false, error
      end
      return true, nil
    end
  end

  def get_budget
    if attributes.include? "budget"
      budget
    else
      '0'
    end
  end

  def get_paid
    if attributes.include? "paid"
      paid
    else
      false
    end
  end

  def get_accepted
    if attributes.include? "accepted"
      accepted
    else
      false
    end
  end

  def get_resolver
    return nil unless attributes.include? "resolver"
    if resolver.attributes.empty?
      nil
    else
      User.find_by_lastname(resolver.name.split.second)
    end
  end

  def self.find_by_external_id(id)
    ticket = TocatTicket.find(:all, params: {search: id}).first
    if ticket.present?
      return TocatTicket.find(ticket.id)
    end
    nil
  end

  def get_orders
    if respond_to? ('orders')
      return orders
    else
      return []
    end
  end

  def redmine
    begin
      return Issue.find(external_id)
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end


  def self.update_resolver(id, resolver)
    if resolver.present? && resolver.to_i != 0
      begin
        connection.post("#{self.prefix}/task/#{id}/resolver", {user_id: resolver}.to_json)
      rescue => error
        # TODO add logger
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete("#{self.prefix}/task/#{id}/resolver")
      rescue => error
        # TODO add logger
        return false, error
      end
      return true, nil
    end
  end

  def self.set_budgets(id, budgets)
    begin
      connection.post("#{self.prefix}/task/#{id}/budget", {budget: budgets}.to_json)
    rescue => error
      # TODO add logger
      return false, error
    end
    return true, nil
  end

  def self.get_budgets(id)
    budgets = []
    begin
      request = connection.get("#{self.prefix}/task/#{id}/budget")
      if request.code.to_i == 200
        return true, [] unless JSON.parse(request.body)['budget'].present?
        budgets_ = JSON.parse(request.body)
        budgets_['budget'].each do |record|
          params = {}
          order = TocatOrder.find(record['order_id'])
          params[:id] = order.id
          params[:budget] = record['budget']
          params[:name] = order.name
          params[:allocatable_budget] = order.allocatable_budget
          params[:free_budget] = order.free_budget
          params[:paid] = order.paid
          params[:invoiced_budget] = order.invoiced_budget
          budgets << OpenStruct.new(params)
        end
        return true, budgets
      else
        # TODO add logger
        return false, JSON.parse(request.body)
      end
    rescue => e
      # TODO add logger
      return false, e
    end
  end

  def self.get_accepted_tasks(accepted=false, id)
    if accepted
      tasks = TocatTicket.find(:all, params: {search: "accepted=1 paid=0 resolver=#{id}", sort: 'external_id:desc', limit:9999999})
    else
      tasks = TocatTicket.find(:all, params: {search: "accepted=0 resolver=#{id}", sort: 'external_id:desc', limit:9999999})
    end
    issues = []
    tasks.each do |task|
      issue = Issue.where(id:task.external_id).first
      if issue.present?
        params = {
          id:      issue.id,
          subject: issue.subject,
          project: issue.project.name,
          project_id: issue.project.id,
          budget: task.budget
        }
        issues << OpenStruct.new(params)
      end
    end
    issues
  end

  protected

  def to_json(options = {})
    self.attributes.to_json(options)
  end
end
