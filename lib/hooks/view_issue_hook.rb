module RedmineTocatClient
  module Hooks
    class ViewsProjectHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, :partial => "issues/tocat"
    end
  end
end


class RedmineMyPluginHookListener < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context)
      stylesheet_link_tag 'tocat_client', :plugin => :redmine_tocat_client
  end
end
