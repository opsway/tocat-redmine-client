module RedmineTocatClient
  module Hooks
    class ViewsProjectHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, :partial => "issues/tocat"
    end
  end
end
