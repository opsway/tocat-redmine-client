module RedmineTocatClient
  module Hooks
    class ViewsProjectHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, :partial => "issues/tocat"
      render_on :view_issues_form_details_bottom	, :partial => "issues/orders"
    end
  end
end
