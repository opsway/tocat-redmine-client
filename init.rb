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

  menu :top_menu, :tocat, { :controller => 'tocat', :action => 'my_tocat' }, :caption => 'Tocat' # TODO add transalate for ru

  Redmine::MenuManager.map :tocat_menu do |menu|
    menu.push :tocat, { :controller => 'tocat', :action => 'my_tocat' }, :caption => :label_my_tocat
    menu.push :orders, { :controller => 'orders', :action => 'index' }, :caption => :label_order_plural
    #menu.push :invoices, { :controller => 'tocat', :action => 'invoices' }, :caption => :label_invoice_plural
  end
end

require_dependency 'redmine_tocat_client'
