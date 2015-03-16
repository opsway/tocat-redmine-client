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

        def available_resolvers
          if tocat.orders.present?
            team = TocatOrder.find(tocat.orders.first.id).team.name
            users = TocatUser.find(:all, params:{search:"team = #{team}", limit:9999999999})
          else
            users =  TocatUser.all
          end
          users
        end

        def orders
          tocat.get_orders
        end

        def available_orders
          if tocat.attributes.include? 'resolver' && tocat.resolver.id.present?
            team = TocatUser.find(tocat.resolver.id).team.name
            orders = TocatOrder.find(:all, params:{search:"team=#{team} paid=0 completed=0 free_budget>0", limit:9999999999})
          else
            orders = TocatOrder.find(:all, params:{search:"paid=0 completed=0 free_budget>0", limit:9999999999})
          end
          orders
        end

        def get_balance_for_order(id)
          budgets.each do |record|
            return record.budget if record.id == id
          end
        end

        def available_orders_as_json
          orders_data = {}
          if tocat.attributes.include? 'resolver' && tocat.resolver.id.present?
            team = TocatUser.find(tocat.resolver.id).team.name
            orders = TocatOrder.find(:all, params:{search:"team=#{team} paid=0 completed=0 free_budget>0", limit:9999999999})
          else
            orders = TocatOrder.find(:all, params:{search:"paid=0 completed=0 free_budget>0", limit:9999999999})
          end
          orders.collect { |t| orders_data[t.id] = t.free_budget}
          return orders_data.to_json
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
