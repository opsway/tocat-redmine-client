class TocatTicket < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'tasks'
  self.element_name = 'task'

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


  def self.find_by_external_id(id)
    ticket = TocatTicket.find(:all, params: {search_query: id}).first
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
    Issue.find(external_id)
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

  protected

  def to_json(options = {})
    self.attributes.to_json(options)
  end
end
