class TocatUser < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'user'

  def self.find_by_login(login)
    TocatUser.all.each { |u| return TocatUser.find(u.id) if u.login.to_s == login}
  end

end
