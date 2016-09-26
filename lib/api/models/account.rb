class Account < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.element_name = 'account'
  self.collection_name = 'accounts'
  add_response_method :http_response
  include AuthTocat

  schema do
    attribute 'id', :integer
    attribute 'name', :string
    attribute 'account_type', :string
    attribute 'type', :string
    attribute 'accountable_id', :string
    attribute 'pay_comission', :boolean
  end
  validates :name, presence: true
  
  def add_access(user_id,default)
    begin
      connection.post("/#{self.class.element_name}/#{id}/add_access",{user_id: user_id, default: default}.to_json, TocatUser.headers)
      return true, nil
    rescue => error
      Rails.logger.info "Exception in Tocat. #{error.message}"
      return false, error
    end
  end
  
  def delete_access(user_id)
    connection.post("/#{self.class.element_name}/#{id}/delete_access",{user_id: user_id}.to_json, TocatUser.headers)
  end

  def to_s
    self.name
  end
  
  def self.linked
    JSON.parse connection.get("/#{collection_name}/linked", TocatUser.headers).body
  end
  
  def self.for_select
    JSON.parse(connection.get("/#{collection_name}/all", TocatUser.headers).body).map{|a| [a['name'],a['id']]}
  end

  def self.find_by_name(name)
    Account.find(:all, params:{search:"#{name}"}).first
  end
end
