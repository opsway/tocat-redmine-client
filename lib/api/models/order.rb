class TocatOrder < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'orders'
  self.element_name = 'order'
  add_response_method :http_response
  include AuthTocat

  class << self
    def available_for_invoice
      response = self.get(:available_for_invoice, { })
      instantiate_collection(response)
    end

    def build(attributes = {})
        attrs = self.format.decode(connection.get("#{new_element_path(attributes)}", headers).body)
        self.new(attrs)
    end
  end


  schema do
    attribute 'id', :integer
    attribute 'parent_order', :string
    attribute 'name', :string
    attribute 'description', :text
    attribute 'team', :string
    attribute 'invoice', :integer
    decimal 'invoiced_budget', 'allocatable_budget', 'free_budget'
    attribute 'internal_order', :boolean
    attribute 'commission', :integer
    attribute 'zohobooks_project_id', :string
    attribute 'accrual_completed_date', :date
  end

  def activity
    begin
      records = []
      JSON.parse(connection.get("#{self.class.prefix}/activity?trackable=order&trackable_id=#{self.id}",TocatOrder.headers).body).each do |record|
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
     rescue => error
       Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
       return []
     end
  end

  def self.find_by_name(name)
    record = TocatOrder.find(:all, params:{search:"#{name}"}).first
  end

  def toggle_campleted
    unless completed
      begin
        connection.post(element_path + '/complete','',TocatOrder.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete(element_path + '/complete',TocatOrder.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    end
  end

  def set_internal
    begin
      connection.post(element_path + '/internal','', TocatOrder.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def set_commission(commission)
    begin
      connection.post(element_path(commission: commission).gsub('?', '/commission?'),'',TocatOrder.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def remove_internal
    begin
      connection.delete(element_path + '/internal',TocatOrder.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end
  def budget
    begin
      return JSON.parse(connection.get(element_path + '/budget', TocatOrder.headers).body)
    rescue
      return []
    end
  end

  def set_reseller
    begin
      connection.post(element_path + '/reseller','',TocatOrder.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def unset_reseller
    begin
      connection.delete(element_path + '/reseller',TocatOrder.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def issues
    issues = []
    budgets = {}
    budget['budget'].each { |r| budgets[r['task_id']] = r['budget']  }
    tasks.each do |task|
      #task.external_id = task.external_id.gsub("#{TocatTicket.company}_",'')
      issue = Issue.where(id: task.external_id.gsub(/\D/,'')).first if task.external_id.match(/\/issues\//) && task.external_id.match(RedmineTocatClient.settings[:company])
      #next unless issue # don't take issue if it not present
      resolver = task.resolver if task.resolver.try(:id)
      if task.present?
       issues << OpenStruct.new( id: task.external_id,
                                 project: issue.try(:project),
                                 budget: budgets[task.id],
                                 resolver: resolver,
                                 subject: issue.try(:subject)||task.external_id,
                                 expenses: task.expenses,
                                 accepted: task.accepted,
                                 paid: task.paid,
                                 issue_id: task.id
                               )
      else
        issues << OpenStruct.new( id: task.external_id,
                                  issue_id: task.id,
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
      connection.post(element_path({invoice_id: id}).gsub('?', '/invoice?'),'',TocatOrder.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def delete_invoice
    begin
      connection.delete(element_path + '/invoice',TocatOrder.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def delete_task(task_id)
    begin
      connection.delete("#{self.class.prefix}/order/#{self.id}/delete_task?task_id=#{task_id}",TocatOrder.headers)
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
      response = connection.post("#{self.class.prefix}/order/#{self.id}/suborder", query.to_json, TocatOrder.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error, nil
    end
    return true, nil, JSON.parse(response.body)
  end

  def editable?
    true
  end

  def load_parent_order
    TocatOrder.find(parent_order)
  rescue ActiveResource::ResourceNotFound => error
    Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
    nil
  end

  protected

  def to_json(options = {})
    self.attributes[:team] = {:id => attributes[:team]}
    self.attributes.to_json(options)
  end
end
