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

  def set_budgets!(budgets)
    post(:budget, '', {budget: [budgets]}.to_json)
  end

  def redmine
    Issue.find(external_id)
  end

  protected

  def to_json(options = {})
    self.attributes.to_json(options)
  end
end
