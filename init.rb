Redmine::Plugin.register :redmine_tocat_client do
  name 'Redmine Tocat Client plugin'
  author 'Alex Gornov'
  description 'This is a client for TOCAT Billing System.'
  version '0.0.1'
  url ''
  author_url 'http://opsway.com/'

  menu :top_menu, :tocat, { :controller => 'tocat', :action => 'index' }, :caption => 'Tocat' # TODO add transalate for ru

end
