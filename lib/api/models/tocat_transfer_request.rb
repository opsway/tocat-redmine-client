class TransferRequest < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'transfer_requests'
  self.element_name = 'transfer_request'
  add_response_method :http_response
  include AuthTocat

  def pay(source_account_id)
    begin
      connection.post("/#{self.class.element_name}/#{id}/pay",{source_account_id: source_account_id}.to_json, TocatUser.headers)
      return true, nil
    rescue => e
      return false, e.message
    end
  end
  
  def self.withdraw(account_id)
    begin
      connection.post("/#{collection_name}/withdraw",{account_id: account_id}.to_json, TocatUser.headers)
      return true, nil
    rescue => e
      return false, e.message
    end
  end
  
  def available_recepients
    all_users = Account.find(:all, params: {limit: 10000, tocat_role: 'view_transfers', search: "account_type == money"})
    all_users.map{|u| [u.name,u.id]}
  end
  def available_for_new
    #an = available_recepients
    #tocat_id = User.current.try(:tocat).try(:id)
    #an.delete_if{|u| u[1] == tocat_id}
    available_recepients
  end
  
  schema do
    attribute 'source_id', :decimal
    attribute 'description', :text
    attribute 'total', :decimal
    attribute 'source_account_id', :decimal
    attribute 'target_account_id', :decimal
  end
end
