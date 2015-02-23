class TocatTransaction < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'transactions'

  def self.get_transactions_for_user(id)
    TocatTransaction.find(:all, params:{user: id})
  end

  def self.get_transactions_for_team(id)
    TocatTransaction.find(:all, params:{team: id})
  end
end
