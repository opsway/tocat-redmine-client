class PaymentRequest < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'payment_requests'
  self.element_name = 'payment_request'
  add_response_method :http_response
  include AuthTocat
  schema do
    attribute 'description', :text
    attribute 'total', :decimal
    attribute 'special', :boolean
    attribute 'salary_account_id', :integer
    attribute 'currency', :text
  end
  STATUSES = %w(new approved dispatched completed canceled rejected)
  def self.min_status(user = User.current)
    return 'new' if user.tocat_allowed_to? :create_payment_request
    return 'approved' if user.tocat_allowed_to? :dispatch_payment_request
    return 'dispatched' if user.tocat_allowed_to? :complete_payment_request
    'new'
  end

  %w(approve cancel reject complete).each do |m|
    define_method m do
      connection.post("/#{self.class.element_name}/#{id}/#{m}",'', PaymentRequest.headers)
    end
  end

  def dispatch(user_email)
    connection.post("/#{self.class.element_name}/#{id}/dispatch",{email: user_email}.to_json, PaymentRequest.headers)
  end
  
  def self.available_source
    User.joins(:tocat_role).includes(:tocat_role).where("tocat_roles.permissions like '%:create_payment_request%'").map{|u| [u.name, u.mail]}
  end
  
  def available_for_dispatch
    User.joins(:tocat_role).includes(:tocat_role).where("tocat_roles.permissions like '%:complete_payment_request%'").map{|u| [u.name, u.mail]}
  end
end
