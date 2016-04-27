class TocatBalanceTransfer < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'balance_transfers'
  self.element_name = 'balance_transfer'
  add_response_method :http_response

  class << self
    def element_path(id, prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      query_options.merge!({:current_user => User.current.name})
      "#{prefix(prefix_options)}#{collection_name}/#{URI.parser.escape id.to_s}#{query_string(query_options)}"
    end

    def collection_path(prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      query_options.merge!({:current_user => User.current.name})
      "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
    end

  end
  
  def available_recepients
    all_users = TocatUser.find(:all, params: {limit: 10000}).select{|u| u.real_money }
    all_users_login = all_users.map(&:login)
    users = User.joins(:tocat_role).includes(:tocat_role).where(login: all_users_login).select{|u| u.tocat_allowed_to? :view_transfers }.map(&:login)
    all_users.select{|u| u.login.in?(users) && User.current.login != u.login }.map{|u| [u.name,u.login]}
  end


  schema do
    attribute 'target_login', :string
    attribute 'description', :text
    attribute 'total', :decimal
    attribute 'btype', :string
  end
end
