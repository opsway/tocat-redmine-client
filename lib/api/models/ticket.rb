class TocatTicket < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'task'

  def self.find_by_name(name)
    all_records = Team.all
    all_records.each { |r| return Team.find(r.id) if r.name == name }
    nil
  end

  def redmine
    Issue.find(external_id)
  end
end
