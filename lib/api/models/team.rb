class TocatTeam < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'teams'

  def self.find_by_name(name)
    TocatTeam.all.each { |team| return team if team.name == name }
  end
end
