class TocatTeam < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.element_name = 'team'
  self.collection_name = 'teams'
  add_response_method :http_response
  include AuthTocat

  schema do
    attribute 'id', :integer
    attribute 'name', :string
    attribute 'links', :integer
    attribute 'manager', :integer
    attribute 'default_commission', :integer
    attribute 'parent_id', :integer
    attribute 'active', :boolean
  end
  validates :name, :default_commission, presence: true
  def to_s
    self.name
  end

  def couch(couchs, team = self)
    p "team - #{team.id} - #{team.name}"
    couch = couchs.find{|u| u.tocat_team.id == team.id}
    return couch if team.parent_id == team.id
    unless couch
      couch = couch(couchs, team.parent) unless team.id == team.parent_id
    end
    couch
  end

  def team_users
    TocatUser.find(:all, params:{search:"team=\"#{name}\""})
  end

  def team_manager
    team_users.find { |user| user.tocat_server_role.name == 'Manager' }
  end

  def parent
    TocatTeam.find(self.parent_id)
  end

  def self.active_teams
    all_teams = TocatTeam.all
    teams_array = []
    all_teams.each { |team| teams_array << team if team.active }
    teams_array
  end

  def self.find_by_name(name)
    TocatTeam.find(:all, params:{search:"#{name}"}).first
  end

  def self.available_for_issue(issue)
    TocatTeam.all
  end
end
