class TocatTicket < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'tasks'

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

  def set_budgets(budgets)
    params = []
    JSON.parse(budgets).each do |budget|
      params << { 'order_id' => budget[0].to_i , 'budget' => budget[1] }
    end
    begin
      post(:budget, '', {budget: params}.to_json)
    rescue => error
      return false, JSON.parse(error.response.body)['message']
    end
    return true, nil
  end

  def redmine
    Issue.find(external_id)
  end

  protected

  def to_json(options = {})
    self.attributes.to_json(options)
  end
end
