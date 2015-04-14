class TocatInvoice < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'invoices'
  self.element_name = 'invoice'
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
    attribute 'external_id', :string
    attribute 'paid', :boolean
  end

  def editable?
    true
  end

  def set_paid
    begin
      connection.post("#{self.class.prefix}/invoice/#{id}/paid")
    rescue => error
      # TODO add logger
      return false, error
    end
    return true, nil
  end

  def remove_paid
    begin
      connection.delete("#{self.class.prefix}/invoice/#{id}/paid")
    rescue => error
      # TODO add logger
      return false, error
    end
    return true, nil
  end

  protected

  def to_json(options = {})
    self.attributes[:team] = {:id => attributes[:team]}
    self.attributes.to_json(options)
  end
end
