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
            order = TocatOrder.find(record['order_id'])
            params[:id] = order.id
            params[:budget] = record['budget']
            params[:name] = order.name
            params[:allocatable_budget] = order.allocatable_budget
            params[:free_budget] = order.free_budget
            params[:paid] = order.paid
            params[:invoiced_budget] = order.invoiced_budget
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
