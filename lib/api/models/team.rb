class TocatTeam < ActiveResource::Base
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'team'
end
