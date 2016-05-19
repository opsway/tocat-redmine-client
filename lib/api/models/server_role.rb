class TocatServerRole < ActiveResource::Base
  unloadable
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'roles'
  self.element_name = 'role'
  include AuthTocat
end
