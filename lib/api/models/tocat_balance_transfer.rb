class TocatBalanceTransfer < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'balance_transfers'
  self.element_name = 'balance_transfer'
  add_response_method :http_response
  include AuthTocat
  
  def available_recepients
    all_users = TocatUser.find(:all, params: {limit: 10000, search: "real_money=1", tocat_role: 'view_transfers'}).select{|u| u.real_money }.map{|u| [u.name,u.login]}
    all_users
  end
  def available_for_new
    an = available_recepients
    an.delete_if{|u| u[1] == User.current.try(:login)}
  end


  schema do
    attribute 'target_login', :string
    attribute 'description', :text
    attribute 'total', :decimal
    attribute 'btype', :string
  end
end
