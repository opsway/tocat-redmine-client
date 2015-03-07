class TocatInvoice < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'invoices'
  add_response_method :http_response

  schema do
    attribute 'id', :integer
    attribute 'client', :string
    attribute 'external_id', :string
    attribute 'paid', :boolean
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
