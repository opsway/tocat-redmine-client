require 'users_helper'

module UsersHelper
  unloadable
  alias_method :old_user_settings_tabs, :user_settings_tabs
  arity = UsersHelper.instance_method(:user_settings_tabs).arity
  if arity == 0
    def user_settings_tabs(user=nil)
      tabs = old_user_settings_tabs #(user)
      tabs << {:name => 'tocat', :partial => 'tocat_roles/tocat', :label => :label_tocat_role}
      tabs
    end
  else
    def user_settings_tabs(user=nil)
      tabs = old_user_settings_tabs(user)
      tabs << {:name => 'tocat', :partial => 'tocat_roles/tocat', :label => :label_tocat_role}
      tabs
    end
  end
end
