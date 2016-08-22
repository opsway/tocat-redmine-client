class TocatTicket < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'tasks'
  self.element_name = 'task'
  add_response_method :http_response
  include AuthTocat

  class << self
    def company
      RedmineTocatClient.settings[:company]
    end
  end
  def internal_id
    return nil unless external_id.match(/\/issues\//)
    return nil unless external_id.match RedmineTocatClient.settings[:company]
    self.external_id.gsub(/\D/,'')
  end

  def activity
    return [] unless User.current.tocat_allowed_to?(:show_activity_feed)
    begin
      records = []
      JSON.parse(connection.get("#{self.class.prefix}/activity?trackable=task&trackable_id=#{id}&limit=9999999",TocatTicket.headers).body).each do |record|
        next if record['key'] == 'task.create'
        data = OpenStruct.new(
            id: "tocat_#{record['id']}",
            css_classes: 'journal has-details',
            created_on: Time.parse(record['created_at']),
            notes: [],
            visible_details: [],
            details: [],
            indice: 0
        )
        if record['owner_id'].present?
          owner = TocatUser.find(record['owner_id'])
          owner = AnonymousUser.first unless owner.present?        
          data.user = owner 
        end
        data.visible_details << OpenStruct.new(
            prop_key: record['key'].split('.').second,
            property: 'attr',
            old_value: record['parameters']['old'],
            value: record['parameters']['new'],
            resolver: nil
        )
        data.details = data.visible_details
        if record['recipient_id'].present?
          recipient = TocatUser.find(record['recipient_id'])
          data.visible_details.first.recipient = recipient
          data.details.first.recipient = recipient
        end
        records << data
      end
      return records
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return []
    end
  end

  def self.events_for(ids, key = nil)
    begin
      records = []
      return records if ids.blank?
      key.nil? ?
          url = "#{self.prefix}/activity?trackable=task&trackable_id=#{ids.join(',')}&limit=9999999" :
          url = "#{self.prefix}/activity?trackable=task&trackable_id=#{ids.join(',')}&key=#{key}&limit=9999999"
      JSON.parse(connection.get(url,TocatTicket.headers).body).each do |record|
        records << OpenStruct.new(id: record["trackable_id"], key: record["key"], parameters: record['parameters'], created_at: record['created_at'])
      end
      return records
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return []
    end
  end

  def toggle_review_requested
    unless review_requested
      begin
        connection.post(element_path + '/review','',TocatTicket.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete(element_path + '/review', TocatTicket.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    end
  end
 
  def set_expenses
    set_expense_param(true)
  end
  def remove_expenses
    set_expense_param(false)
  end

  def set_expense_param(val)
    if val
      begin
        connection.post(element_path + '/expenses', '', TocatTicket.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete(element_path + '/expenses', TocatTicket.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
    end
  end

  def toggle_paid # FIXME WTF? Rename to toggle_accepted
    unless accepted
      begin
        connection.post(element_path + '/accept', '', TocatTicket.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete(element_path + '/accept', TocatTicket.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    end
  end

  def get_budget # FIXME Probably not need this anymore
    if attributes.include? "budget"
      budget
    else
      0
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
      resolver
    end
  end

  def self.find_by_external_id(id) # FIXME Refactor to use real search
    begin 
      ticket = TocatTicket.find(:all, params: {search: "external_id=#{id}"}).first
      if ticket.present?
        return TocatTicket.find(ticket.id) # WTF?? FIXME TODO - different serializers
      end
      nil
    rescue => e #ActiveResource::UnauthorizedAccess
      Rails.logger.info "tocat failed - #{e.message}"
      nil
    end
  end

  def get_orders # FIXME Probably not need this anymore
    if respond_to? ('orders')
      return orders
    else
      return []
    end
  end

  def redmine
    begin
      return Issue.find(internal_id) if internal_id
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end


  def self.update_resolver(id, resolver) # FIXME Why class method?
    if resolver.present? && resolver.to_i != 0
      begin #          FIXME Use element_path(id) below
        connection.post("#{self.prefix}task/#{id}/resolver", {user_id: resolver}.to_json, TocatTicket.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete(element_path(id) + '/resolver',TocatTicket.headers)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    end
  end

  def self.set_budgets(id, budgets) # FIXME Why class method?
    begin  #          FIXME Use element_path(id) below
      connection.post("#{self.prefix}task/#{id}/budget", {budget: budgets}.to_json, TocatTicket.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def self.get_budgets(id) # FIXME Why class method?
    budgets = []
    begin#          FIXME Use element_path(id) below
      request = connection.get("#{self.prefix}task/#{id}/budget", TocatTicket.headers)
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
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
  end

  def self.get_accepted_tasks(accepted=false, id) # FIXME Why class method?
    if accepted
      tasks = TocatTicket.find(:all, params: {search: "accepted=1 paid=0 resolver=#{id}", sort: 'external_id:desc', limit:9999999})
    else
      tasks = TocatTicket.find(:all, params: {search: "accepted=0 resolver=#{id}", sort: 'external_id:desc', limit:9999999})
    end
    issues = []
    tasks.each do |task|
      issue = Issue.where(id: task.internal_id).first
      if issue.present?
        params = {
          id:      issue.id,
          subject: issue.subject,
          project: issue.project.name,
          project_id: issue.project.id,
          budget: task.budget,
          task_id: task.id
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
