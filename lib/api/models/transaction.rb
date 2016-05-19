class TocatTransaction < ActiveResource::Base
  unloadable
  include AuthTocat
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'transactions'
  self.element_name = 'transaction'
  add_response_method :http_response
  

  schema do
    attribute 'id', :integer
    attribute 'user_id', :string
    attribute 'comment', :string
    attribute 'account_type', :string
    attribute 'total', :decimal
  end

  def self.get_transactions_for_user(id)
    TocatTransaction.find(:all, params:{user: id, limit:9999999, sort:'created_at:desc'})
  end

  def self.get_transactions_for_team(id)
    TocatTransaction.find(:all, params:{team: id, limit:9999999, sort:'created_at:desc'})
  end

  protected

  def to_json(options = {})
    self.attributes[:account] = {:id => self.attributes.delete(:account_id)}
    self.attributes.to_json(options)
  end
end
