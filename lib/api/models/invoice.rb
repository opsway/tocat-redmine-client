class TocatInvoice < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'invoice'

  def get_orders
    #TODO REFACTOR!!!
    orders = []
    TocatOrder.all.each do |order|
      order = TocatOrder.find(order.id)
      unless order.invoice.attributes.empty?
        orders << order if order.invoice.id == id
      end
    end
    orders
  end
end
