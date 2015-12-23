class TocatOrder < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'orders'
  self.element_name = 'order'
  add_response_method :http_response

  class << self
    def element_path(id, prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      query_options.merge!({:current_user => User.current.name})
      "#{prefix(prefix_options)}#{element_name}/#{URI.parser.escape id.to_s}#{query_string(query_options)}"
    end

    def collection_path(prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      query_options.merge!({:current_user => User.current.name})
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

  def activity
    begin
      records = []
      JSON.parse(connection.get("#{self.class.prefix}/activity?trackable=order&trackable_id=#{self.id}").body).each do |record|
        recipient = nil
        unless record["recipient_id"].nil?
          case record["recipient_type"]
          when "Invoice"
            recipient = TocatInvoice.find(record["recipient_id"].to_i)
          when "Order"
            recipient = TocatOrder.find(record["recipient_id"].to_i)
          when "User"
            recipient = TocatUser.find(record["recipient_id"].to_i)
          when "Team"
            recipient = TocatTeam.find(record["recipient_id"].to_i)
          end
        end
        owner = nil
        if record['owner_id'].present?
          owner = TocatUser.find(record['owner_id'])
        end
        records << OpenStruct.new(key: record["key"], recipient: recipient, parameters: record['parameters'], created_at: record['created_at'], owner: owner)      end
       return records
     rescue
       return []
     end
  end

  def self.find_by_name(name)
    record = TocatOrder.find(:all, params:{search:"#{name}"}).first
  end

  def toggle_campleted
    unless completed
      begin
        connection.post(element_path.gsub('?', '/complete?'))
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete(element_path.gsub('?', '/complete?'))
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    end
  end

  def budget
    begin
      return JSON.parse(connection.get(element_path.gsub('?', '/budget?')).body)
    rescue
      return []
    end
  end

  def issues
    issues = []
    budgets = {}
    budget['budget'].each { |r| budgets[r['task_id']] = r['budget']  }
    tasks.each do |task|
      issue = Issue.where(id: task.internal_id).first
      if issue.present?
       resolver = task.resolver if task.resolver.try(:id)
       issues << OpenStruct.new( id: task.internal_id,
                                 project: issue.project,
                                 budget: budgets[task.id],
                                 resolver: resolver,
                                 subject: issue.subject
                               )
      else
        issues << OpenStruct.new( id: task.internal_id,
                                  project: nil,
                                  budget: budgets[task.id],
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
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
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
      connection.post(element_path({invoice_id: id}).gsub('?', '/invoice?'))
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def delete_invoice
    begin
      connection.delete(element_path.gsub('?', '/invoice?'))
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
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
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
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
