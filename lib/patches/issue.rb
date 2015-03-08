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

        def available_orders
          @orders_data = {}
          orders_ = []
          all_orders = TocatOrder.all
          presented_orders = orders.collect(&:id)
          all_orders.each do |order|
            unless presented_orders.include? order.id
              orders_ << order
            end
          end
          orders_
        end

        def get_balance_for_order(id)
          budgets.each do |record|
            return record.budget if record.id == id
          end
        end

        def available_orders_as_json
          @orders_data = {}
          orders_ = []
          all_orders = TocatOrder.all
          presented_orders = orders.collect(&:id)
          all_orders.each do |order|
            unless presented_orders.include? order.id
              orders_ << order
            end
          end
          orders_.collect { |t| @orders_data[t.id] = t.free_budget}
          return @orders_data.to_json
        end

        def budgets
          status, payload = TocatTicket.get_budgets(tocat.id)
          if status
            return payload
          else
            return []
          end
        end
      end
    end
  end
end


unless Issue.included_modules.include?(RedmineTocatClient::Patches::IssuePatch)
  Issue.send(:include, RedmineTocatClient::Patches::IssuePatch)
end
