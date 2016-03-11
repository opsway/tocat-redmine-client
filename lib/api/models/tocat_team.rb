class TocatTeam < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.element_name = 'team'
  self.collection_name = 'teams'
  add_response_method :http_response

  has_many :tocat_users

  schema do
    attribute 'id', :integer
    attribute 'name', :string
    attribute 'links', :integer
    attribute 'manager', :integer
    attribute 'default_commission', :integer
  end
  validates :name, :default_commission, presence: true
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

  def team_users
    tocat_users.find_all { |user| user.tocat_team.id == id }
  end

  def team_manager
    team_users.find { |user| user.tocat_server_role.id == 1 }
  end

  def self.find_by_name(name)
    TocatTeam.find(:all, params:{search:"#{name}"}).first
  end

  def self.available_for_issue(issue)
    TocatTeam.all
  end
end
