module RedmineTocatClient
  module Patches
    module GroupPatch
      def self.included(base) # :nodoc:
        unloadable
        base.send(:include, InstanceMethods)
      end
      module InstanceMethods
        def tocat
          TocatTeam.find_by_name(name)
        end
      end
    end
  end
end


unless Group.included_modules.include?(RedmineTocatClient::Patches::GroupPatch)
  Group.send(:include, RedmineTocatClient::Patches::GroupPatch)
end
