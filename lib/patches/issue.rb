module RedmineTocatClient
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
      end
      module InstanceMethods
        def tocat
          task = TocatTicket.find_by_external_id(id)
          unless task
            task = TocatTicket.create(external_id: id)
          end
          task
        end

        def orders
          tocat.get_orders
        end

        def budgets
          budgets = []
          tocat.get(:budget).each do |record|
            params = {}
            record.each do |r|
              params[r.first] = r.second
            end
            budgets << OpenStruct.new(params)
          end
          budgets
        end
      end
    end
  end
end


unless Issue.included_modules.include?(RedmineTocatClient::Patches::IssuePatch)
  Issue.send(:include, RedmineTocatClient::Patches::IssuePatch)
end
