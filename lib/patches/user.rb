require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module RedmineTocatClient
  module Patches
    module UserPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
      end
      module InstanceMethods
        def tocat
          TocatUser.find_by_login(login)
        end
      end
    end
  end
end


unless User.included_modules.include?(RedmineTocatClient::Patches::UserPatch)
  User.send(:include, RedmineTocatClient::Patches::UserPatch)
end
