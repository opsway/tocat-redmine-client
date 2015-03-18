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
          },:partial => 'settings/tocat_settings'

  menu :top_menu, :tocat, { :controller => 'tocat', :action => 'my_tocat' },
                          :if => Proc.new{ User.current.allowed_to?({:controller => 'tocat', :action => 'my_tocat'},
                                          nil, {:global => true})}, :caption => 'TOCAT'

  project_module :redmine_tocat_client do

    permission :view_my_tocat_page, {
      :tocat => [:my_tocat]
    }

    permission :view_group_tocat_page, {
      :tocat => [:my_tocat]
    }

    permission :show_invoices, {
      :invoices => [:index, :show]
    }

    permission :create_invoices, {
      :invoices => [:new, :create]
    }

    permission :edit_invoices, {
      :invoices => [:set_paid, :set_unpaid, :edit, :update]
    }

    permission :delete_invoices, {
      :invoices => [:destroy]
    }

    permission :show_orders, {
      :orders => [:index, :show]
    }

    permission :create_orders, {
      :orders => [:new, :create, :create_suborder]
    }

    permission :edit_orders, {
      :orders => [:edit, :update]
    }

    permission :delete_orders, {
      :orders => [:destroy]
    }

  end


  Redmine::MenuManager.map :tocat_menu do |menu|
    menu.push :tocat, { :controller => 'tocat', :action => 'my_tocat' }, :caption => :label_my_tocat
    menu.push :orders, { :controller => 'orders', :action => 'index' },
              :if => Proc.new{ User.current.allowed_to?({:controller => 'orders', :action => 'index'},
                    nil, {:global => true})},
              :caption => :label_order_plural
    menu.push :invoices, { :controller => 'invoices', :action => 'index' },
              :if => Proc.new{ User.current.allowed_to?({:controller => 'invoices', :action => 'index'},
                    nil, {:global => true})},
              :caption => :label_invoice_plural
    # menu.push :issues, { :controller => 'tickets', :action => 'index' },
    #           :if => Proc.new{ User.current.allowed_to?({:controller => 'invoices', :action => 'index'},
    #                 nil, {:global => true})},
    #           :caption => :label_issue_plural
  end
end

require_dependency 'redmine_tocat_client'
