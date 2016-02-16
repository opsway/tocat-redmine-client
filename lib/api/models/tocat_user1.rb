require 'active_resource'
class TocatUser1 < ActiveResource::Base
  unloadable
  include ActiveModel::Validations
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'users'
  self.element_name = 'user'
  #self.include_root_in_json = true
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
end
