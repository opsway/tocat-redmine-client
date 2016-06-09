Redmine::Plugin.register :redmine_tocat_client do
  name 'Redmine TOCAT Client plugin'
  author 'Alex Gornov'
  description 'This is a client for TOCAT Billing System.'
  version '0.0.1'
  url 'https://github.com/opsway/tocat-server'
  author_url 'http://opsway.com/'

  requires_redmine :version_or_higher => '2.0.3'

  settings :default => {
    'host' => 'http://tocat.opsway.com',
    'company' => 'opsway',
    'apikey' => 'apikey'
          },:partial => 'settings/tocat_settings'

  menu :top_menu, :tocat, { :controller => 'tocat', :action => 'my_tocat' },
                          :if => Proc.new{ User.current.tocat_allowed_to?(:show_tocat_page) }, :caption => 'TOCAT'

  menu :admin_menu, :tocat_roles, { :controller => 'tocat_roles', :action => 'index' }, :caption => 'TOCAT Roles and Permissions'


  Redmine::MenuManager.map :tocat_menu do |menu|
    menu.push :tocat, { :controller => 'tocat', :action => 'my_tocat' }, :caption => :label_my_tocat
    menu.push :orders, { :controller => 'orders', :action => 'index' },
              :if => Proc.new{ User.current.tocat_allowed_to?(:show_orders)},
              :caption => :label_order_plural
    menu.push :invoices, { :controller => 'invoices', :action => 'index' },
              :if => Proc.new{ User.current.tocat_allowed_to?(:show_invoices)},
              :caption => :label_invoice_plural
    menu.push :tickets, { :controller => 'tickets', :action => 'index' },
              :if => Proc.new{ User.current.tocat_allowed_to?(:show_issues)},
              :caption => :label_issue_plural
    menu.push :transactions, { :controller => 'transactions', :action => 'index' },
              :if => Proc.new{ User.current.tocat_allowed_to?(:show_transactions)},
              :caption => :label_transaction_plural
    menu.push :users, { :controller => 'tocat_users', :action => 'index' },
              :caption => 'Users'
    menu.push :teams, { :controller => 'tocat_teams', :action => 'index' },
              :caption => 'Teams'
    menu.push :status, { :controller => 'status', :action => 'status' },
              :if => Proc.new{ User.current.tocat_allowed_to?(:show_status_page)},
              :caption => :label_status
    menu.push :balance_transfer, { :controller => 'internal_payments', :action => 'index' },
              :if => Proc.new{ User.current.tocat_allowed_to?(:view_transfers)},
              :caption => :label_transfers
    menu.push :transfer_request, { :controller => 'internal_invoices', :action => 'index' },
              :if => Proc.new{ User.current.tocat_allowed_to?(:view_transfers)},
              :caption => :label_transfer_requests
    menu.push :payment_request, { :controller => 'external_payments', :action => 'index'},
              :if => Proc.new { User.current.tocat_allowed_to?(:view_payment_requests) },
              :caption => :label_payment_request

  end
  ActiveResource::Base.include_root_in_json = true
end

require_dependency 'redmine_tocat_client'
