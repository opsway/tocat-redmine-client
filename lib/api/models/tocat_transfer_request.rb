class TransferRequest < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'transfer_requests'
  self.element_name = 'transfer_request'
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
  def pay
    self.post('pay', {:current_user => User.current.name})
  end
  
  def available_recepients
    all_users = TocatUser.find(:all, params: {limit: 10000}).select{|u| u.real_money }
    all_users_login = all_users.map(&:login)
    users = User.joins(:tocat_role).includes(:tocat_role).where(login: all_users_login).select{|u| u.tocat_allowed_to? :view_transfers }.map(&:login)
    all_users.select{|u| u.login.in?(users) }.map{|u| [u.name,u.id]}
  end
  def available_for_new
    an = available_recepients
    tocat_id = User.current.try(:tocat).try(:id)
    an.delete_if{|u| u[1] == tocat_id}
  end
  
  schema do
    attribute 'source_id', :decimal
    attribute 'description', :text
    attribute 'total', :decimal
  end
end
