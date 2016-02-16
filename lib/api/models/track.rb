require 'active_resource'
class TocatTrack < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'tocat_users'
  self.element_name = 'tocat_user'
end
