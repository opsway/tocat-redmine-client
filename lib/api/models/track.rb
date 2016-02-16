require 'active_resource'
class TocatTrack < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'users'
  self.element_name = 'user'
end
