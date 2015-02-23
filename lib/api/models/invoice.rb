class TocatInvoice < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'invoices'
  add_response_method :http_response

  def editable?
    true
  end

end
