class TocatTransaction < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'transactions'
  self.element_name = 'transaction'
  add_response_method :http_response

  class << self
    def element_path(id, prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      query_options.merge!({:current_user => User.current.name})
      "#{prefix(prefix_options)}#{element_name}/#{URI.parser.escape id.to_s}#{query_string(query_options)}"
    end

    def collection_path(prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      query_options.merge!({:current_user => User.current.name})
      "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
    end
  end

  schema do
    attribute 'id', :integer
    attribute 'user_id', :string
    attribute 'comment', :string
    attribute 'account_type', :string
    attribute 'total', :decimal
  end

  def self.get_transactions_for_user(id)
    TocatTransaction.find(:all, params:{user: id, limit:100, sort:'created_at:desc'})
  end

  def self.get_transactions_for_team(id)
    TocatTransaction.find(:all, params:{team: id, limit:100, sort:'created_at:desc'})
  end

  protected

  def to_json(options = {})
    self.attributes[:account] = {:id => self.attributes.delete(:account_id)}
    self.attributes.to_json(options)
  end
end
