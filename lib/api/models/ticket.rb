class TocatTicket < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'tasks'
  self.element_name = 'task'
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

  def activity
    return [] unless User.current.tocat_allowed_to?(:show_activity_feed)
    begin
      records = []
      JSON.parse(connection.get("#{self.class.prefix}/activity?trackable=task&trackable_id=#{id}&limit=9999999").body).each do |record|
        next if record['key'] == 'task.create'
        data = OpenStruct.new(
            id: "tocat_#{record['id']}",
            css_classes: 'journal has-details',
            created_on: Time.parse(record['created_at']),
            notes: [],
            details: [],
            indice: 0
        )
        if record['owner_id'].present?
          owner = TocatUser.find(record['owner_id'])
          data.user = User.where(firstname: owner.name.split().first, lastname: owner.name.split().second).first
        end
        data.details << OpenStruct.new(
            prop_key: record['key'].split('.').second,
            property: 'attr',
            old_value: record['parameters']['old'],
            value: record['parameters']['new'],
            resolver: nil
        )
        if record['recipient_id'].present?
          recipient = TocatUser.find(record['recipient_id'])
          data.details.first.recipient = User.where(firstname: recipient.name.split().first, lastname: recipient.name.split().second).first
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
      key.nil? ?
          url = "#{self.prefix}/activity?trackable=task&trackable_id=#{ids.join(',')}&limit=9999999" :
          url = "#{self.prefix}/activity?trackable=task&trackable_id=#{ids.join(',')}&key=#{key}&limit=9999999"
      JSON.parse(connection.get(url).body).each do |record|
        records << OpenStruct.new(id: record["trackable_id"], key: record["key"], parameters: record['parameters'], created_at: record['created_at'])
      end
      return records
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return []
    end
  end

  def toggle_paid # FIXME WTF? Rename to toggle_accepted
    unless accepted
      begin
        connection.post(element_path.gsub('?', '/accept?'))
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete(TocatTicket.element_path(self.id).gsub('?', '/accept?'))
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
      User.find_by_lastname(resolver.name.split.second)
    end
  end

  def self.find_by_external_id(id) # FIXME Refactor to use real search
    ticket = TocatTicket.find(:all, params: {search: id}).first
    if ticket.present?
      return TocatTicket.find(ticket.id)
    end
    nil
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
      return Issue.find(external_id)
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end


  def self.update_resolver(id, resolver) # FIXME Why class method?
    if resolver.present? && resolver.to_i != 0
      begin #          FIXME Use element_path(id) below
        connection.post("#{self.prefix}task/#{id}/resolver", {user_id: resolver, current_user: User.current.name}.to_json)
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    else
      begin
        connection.delete(element_path(id).gsub('?', '/resolver?'))
      rescue => error
        Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
        return false, error
      end
      return true, nil
    end
  end

  def self.set_budgets(id, budgets) # FIXME Why class method?
    begin  #          FIXME Use element_path(id) below
      connection.post("#{self.prefix}task/#{id}/budget", {budget: budgets, current_user: User.current.name}.to_json)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def self.get_budgets(id) # FIXME Why class method?
    budgets = []
    begin#          FIXME Use element_path(id) below
      request = connection.get("#{self.prefix}task/#{id}/budget")
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
      issue = Issue.where(id:task.external_id).first
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
