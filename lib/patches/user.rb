require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module RedmineTocatClient
  module Patches
    module UserPatch
      def self.included(base) # :nodoc:
        unloadable
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_one :tocat_user_role, class_name: "TocatUserRole"
          has_one :tocat_role, through: :tocat_user_role, class_name: "TocatRole"
        end
      end
      module InstanceMethods
        def tocat
          TocatUser.find_by_mail(self.mail) rescue nil
        end
        def permissions
          @permissions ||= JSON.parse(RestClient.get("#{RedmineTocatClient.settings[:host]}/acl", TocatUser.headers)).map(&:to_sym) rescue [] #TODO REFACTOR THIS
          @permissions
        end
        def tocat_allowed_to?(action)
          return false if permissions.blank?
          permissions.include? action
        end
      end
    end
  end
end

unless User.included_modules.include?(RedmineTocatClient::Patches::UserPatch)
  User.send(:include, RedmineTocatClient::Patches::UserPatch)
end
