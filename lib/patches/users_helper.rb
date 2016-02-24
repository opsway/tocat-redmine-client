require 'users_helper'

module UsersHelper
  unloadable
  alias_method :old_user_settings_tabs, :user_settings_tabs
  def user_settings_tabs(user=nil)
    tabs = old_user_settings_tabs #(user)
    tabs << {:name => 'tocat', :partial => 'tocat_roles/tocat', :label => :label_tocat_role}
    tabs
  end
end
