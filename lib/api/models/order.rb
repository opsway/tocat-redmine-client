class TocatOrder < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'orders'
  self.element_name = 'order'
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


  schema do
    attribute 'id', :integer
    attribute 'parent_order', :string
    attribute 'name', :string
    attribute 'description', :text
    attribute 'team', :string
    decimal 'invoiced_budget', 'allocatable_budget', 'free_budget'
  end

  def self.find_by_name(name)
    record = TocatOrder.find(:all, params:{search:"#{name}"}).first
  end

  def issues
    issues = []
    tasks.each do |task|
      issue = Issue.where(id: task.external_id).first
      if issue.present?
        if task.resolver.attributes.include? 'name'
          resolver = User.where(lastname: task.resolver.name.split).first
        else
          resolver = nil
        end
        issues << OpenStruct.new( id: task.external_id,
                                  project: issue.project,
                                  budget: task.budget,
                                  resolver: resolver,
                                  subject: issue.subject
                                )
      else
        issues << OpenStruct.new( id: 0,
                                  project: nil,
                                  budget: task.budget,
                                  resolver: resolver,
                                  subject: 'Can not found task. Please, contact administrator.'
                                )
      end
    end
    issues
  end

  def get_team
    team
  end

  def parent
    unless parent_order.attributes.empty?
      begin
        return TocatOrder.find(parent_order.id)
      rescue
        return OpenStruct.new id: parent_order.id, name: 'Parent order doesn\'t exists'
      end
    else
      return nil
    end
  end

  def fmr
    ((1 - (allocatable_budget.to_f/invoiced_budget.to_f)) * 100).round(2)
  end

  def set_invoice(id)
    begin
      connection.post("#{self.class.prefix}/order/#{self.id}/invoice", {invoice_id: id}.to_json)
    rescue => error
      # TODO add logger
      return false, error
    end
    return true, nil
  end

  def delete_invoice
    begin
      connection.delete("#{self.class.prefix}/order/#{self.id}/invoice")
    rescue => error
      # TODO add logger
      return false, error
    end
    return true, nil
  end

  def get_invoice
    unless invoice.attributes.empty?
      return TocatInvoice.find(invoice.id)
    end
    nil
  end

  def set_suborder(query)
    response = ''
    begin
      response = connection.post("#{self.class.prefix}/order/#{self.id}/suborder", query.to_json)
    rescue => error
      # TODO add logger
      return false, error, nil
    end
    return true, nil, JSON.parse(response.body)
  end

  def editable?
    true
  end

  protected

  def to_json(options = {})
    self.attributes[:team] = {:id => attributes[:team]}
    self.attributes.to_json(options)
  end
end
