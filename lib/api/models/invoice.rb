class TocatInvoice < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'invoice'
end
