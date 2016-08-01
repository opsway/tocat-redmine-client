require 'active_resource'
class TocatUser < ActiveResource::Base
  unloadable
  include ActiveModel::Validations
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'users'
  self.element_name = 'user'
  #self.include_root_in_json = true
  add_response_method :http_response
  include AuthTocat

  schema do
    attribute 'id', :integer
    attribute 'login', :string
    attribute 'name', :string
    attribute 'team', :integer
    attribute 'role', :integer
    attribute 'email', :string
    attribute 'real_money', :integer
    decimal 'daily_rate'
    attribute :tocat_server_role, :integer
    attribute :tocat_team, :integer
  end
  validates :login, :name, :team, :daily_rate, presence: true
  validates_presence_of  :role, on: :create
  def to_s
    self.name
  end
  def set_role(role_id)
    begin
      connection.post("#{self.class.prefix}/user/#{id}/set_role", { role: role_id}.to_json, TocatUser.headers)
      true
     rescue => e
       Rails.logger.error(e.message, e.backtrace)
       false
     end
  end

  def activity
    begin
       return JSON.parse(connection.get("#{self.class.prefix}/activity?owner=user&owner_id=#{self.id}",TocatUser.headers).body)
     rescue
       return []
     end
  end
  
  def add_payment(comment, total)
    begin
      connection.post("#{self.class.prefix}/user/#{id}/add_payment", { comment: comment, total: total }.to_json, TocatUser.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end

  def add_salary(comment, total)
    begin
      connection.post("#{self.class.prefix}/user/#{id}/salary_checkin", { comment: comment, total: total }.to_json, TocatUser.headers)
    rescue => error
      Rails.logger.info "\e[31mException in Tocat. #{error.message}, #{error.backtrace.first}\e[0m"
      return false, error
    end
    return true, nil
  end


  def self.find_by_mail(mail)
    begin
    return TocatUser.find(:all, params:{search:"email=#{mail}"}).first
    rescue ActiveResource::UnauthorizedAccess
      nil
    end
  end

  def self.find_by_name(name)
    return TocatUser.find(:all, params:{search:"#{name}"}).first
  end
  def redmine
    User.where(login: self.login).first
  end
  protected

end
