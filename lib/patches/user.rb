require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module RedmineTocatClient
  module Patches
    module UserPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_one :tocat_user_role, class_name: "TocatUserRole"
          has_one :tocat_role, through: :tocat_user_role, class_name: "TocatRole"
        end
      end
      module InstanceMethods
        def tocat
          TocatUser.find_by_name(name)
        end
        def tocat_allowed_to?(action)
          return false unless self.tocat_role.present?
          self.tocat_role.allowed_to?(action)
        end
      end
    end
  end
end

unless User.included_modules.include?(RedmineTocatClient::Patches::UserPatch)
  User.send(:include, RedmineTocatClient::Patches::UserPatch)
end
