module RedmineTocatClient
  module Hooks
    class ViewsProjectHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, :partial => "issues/tocat"
    end
    class ViewsProjectHook < Redmine::Hook::ViewListener
      def helper_issues_show_detail_after_setting(context = { })
        if context[:detail].prop_key == 'budget_update'
          if context[:detail].old_value.any?
            old_orders = TocatOrder.find(:all, params: {search: context[:detail].old_value.collect {|r| r['order_id']}.map {|r| "id = #{r}"}.join(' OR ')})
            old_val = context[:detail].old_value
            context[:detail].old_value = old_orders.map { |o| "#{link_to o.name, order_path(o)}: #{old_val.select{|o_| o_['order_id'] == o.id}.first['budget']}" }.join(', ').html_safe
          else
            context[:detail].old_value = nil
          end
          if context[:detail].value.any?
            orders = TocatOrder.find(:all, params: {search: context[:detail].value.collect {|r| r['order_id']}.map {|r| "id = #{r}"}.join(' OR ')})
            val = context[:detail].value
            context[:detail].value = orders.map { |o| "#{link_to o.name, order_path(o)}: #{val.select{|o_| o_['order_id'] == o.id}.first['budget']}"}.join(', ').html_safe
          else
            context[:detail].value = nil
          end
        end
        if context[:detail].prop_key == 'accepted_update'
          context[:detail].old_value = l(context[:detail].old_value == false ? :general_text_No : :general_text_Yes)
          context[:detail].value = l(context[:detail].value == false ? :general_text_No : :general_text_Yes)
        end
        if context[:detail].prop_key == 'paid_update'
          context[:detail].old_value = l(context[:detail].old_value == false ? :general_text_No : :general_text_Yes)
          context[:detail].value = l(context[:detail].value == false ? :general_text_No : :general_text_Yes)
        end
        if context[:detail].prop_key == 'review_requested'
          context[:detail].old_value = l(context[:detail].old_value == false ? :general_text_No : :general_text_Yes)
          context[:detail].value = l(context[:detail].value == false ? :general_text_No : :general_text_Yes)
        end
        if context[:detail].prop_key == 'resolver_update'
          if context[:detail].recipient
            context[:detail].value = "#{link_to_user(context[:detail].recipient)}".html_safe
          else
            context[:detail].value = nil
          end
        end
      end
    end
  end
end


class RedmineMyPluginHookListener < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context)
      stylesheet_link_tag 'tocat_client', :plugin => :redmine_tocat_client
  end
end
