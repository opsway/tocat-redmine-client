require 'active_resource'
class TocatUser < ActiveResource::Base
  unloadable
  include ActiveModel::Validations
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'users'
  self.element_name = 'user'
  #self.include_root_in_json = true
  add_response_method :http_response

  schema do
    attribute 'id', :integer
    attribute 'login', :string
    attribute 'name', :string
    attribute 'team', :integer
    attribute 'role', :integer
    decimal 'daily_rate'
  end
  validates :login, :name, :team, :role, :daily_rate, presence: true
  def to_s
    self.name
  end

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

  def activity
    begin
       return JSON.parse(connection.get("#{self.class.prefix}/activity?owner=user&owner_id=#{self.id}").body)
     rescue
       return []
     end
  end

  def add_payment(comment, total)
    begin
      connection.post("#{self.class.prefix}/user/#{id}/add_payment", { comment: comment, total: total, current_user: User.current.name }.to_json)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def self.find_by_login(login)
    return TocatUser.find(:all, params:{search:"login=#{login}"}).first
  end

  def self.find_by_name(name)
    return TocatUser.find(:all, params:{search:"#{name}"}).first
  end
  def redmine
    User.where(login: self.login).first
  end
  protected

end
