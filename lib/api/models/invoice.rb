class TocatInvoice < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'invoices'
  self.element_name = 'invoice'
  add_response_method :http_response
  include AuthTocat
 
  schema do
    attribute 'id', :integer
    attribute 'external_id', :string
    attribute 'paid', :boolean
  end

  def activity
    begin
      records = []
      JSON.parse(connection.get("#{self.class.prefix}activity?trackable=invoice&trackable_id=#{self.id}").body,TocatInvoice.headers).each do |record|
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
        records << OpenStruct.new(key: record["key"], recipient: recipient, parameters: record['parameters'], created_at: record['created_at'], owner: owner)
      end
       return records
     rescue => error
       Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
       return []
     end
  end

  # FIXME Probably paid setters should be in one method?
  def set_paid
    begin
      connection.post(element_path.gsub('?', '/paid?'),'',TocatInvoice.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def remove_paid
    begin
      connection.delete(element_path.gsub('?', '/paid?'),TocatInvoice.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
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
