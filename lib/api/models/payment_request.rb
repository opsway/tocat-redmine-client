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
    attribute 'bonus', :boolean
    attribute 'source_account_id', :decimal
  end
  STATUSES = %w(new completed canceled)
  def self.min_status(user = User.current)
    'new'
  end

  %w(cancel complete).each do |m|
    define_method m do
      connection.post("/#{self.class.element_name}/#{id}/#{m}",'', PaymentRequest.headers)
    end
  end

  def self.available_source
    TocatUser.find(:all, params: {limit: 10000, tocat_role: 'create_payment_request'}).map{|u| [u.name, u.email]}
  end
end
