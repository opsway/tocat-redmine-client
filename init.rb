Redmine::Plugin.register :redmine_tocat_client do
  name 'Redmine Tocat Client plugin'
  author 'Alex Gornov'
  description 'This is a client for TOCAT Billing System.'
  version '0.0.1'
  url ''
  author_url 'http://opsway.com/'

  requires_redmine :version_or_higher => '2.0.3'
  settings :default => {
    'host' => 'test'
  },
           :partial => 'settings/tocat_settings'

  menu :top_menu, :tocat, { :controller => 'tocat', :action => 'index' }, :caption => 'Tocat' # TODO add transalate for ru

end

require_dependency 'redmine_tocat_client'
