# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match '/tocat' => 'tocat#my_tocat', as: :my_tocat, via: [:get]
#match '/tocat/invoices' => 'tocat#invoices', as: :invoices, via: [:get]
#match '/tocat/invoices/:invoice_id' => 'tocat#show_invoice', as: :show_invoice, via: [:get]
resources :invoices, path: '/tocat/invoices'
resources :tocat_users, path: '/tocat/users' do
  delete :makeactive, on: :member
end
resources :orders, path: '/tocat/orders'
resources :tickets, path: '/tocat/issues'
resources :tocat_roles, path: '/tocat/roles'
resources :transactions, path: '/tocat/transactions'
match '/tocat/set_role' => 'tocat_roles#set_role', via: [:post, :put]
match '/tocat/new_suborder' => 'orders#create_suborder', as: :suborder, via: [:post, :put]
match '/tocat/budget' => 'tocat#budget_dialog', via: :get
match '/tocat/status' => 'status#status', via: :get
match '/tocat/status/:id/checked' => 'status#checked', as: :checked, via: [:post, :delete]
match '/tocat/orders/:id/invoice' => 'orders#invoices', as: :order_invoices, via: :get
match '/tocat/orders/:id/invoice' => 'orders#set_invoice', as: :order_invoices, via: [:post, :put]
match '/tocat/orders/:id/invoice' => 'orders#delete_invoice', as: :order_invoices, via: [:delete]
match '/tocat/orders/:id/completed' => 'orders#toggle_complete', as: :order_complete, via: [:post, :put]
match '/tocat/orders/:id/completed' => 'orders#toggle_uncomplete', as: :order_uncomplete, via: [:delete]
match '/tocat/budget' => 'tocat#delete_budget', via: :delete
match '/tocat/budget' => 'tocat#save_budget_dialog', via: [:post, :put]
match '/tocat/resolver' => 'tocat#update_resolver', via: [:post, :put]
match '/tocat/invoices/:id/paid' => 'invoices#set_paid', as: :invoice_paid, via: [:post, :put]
match '/tocat/invoices/:id/paid' => 'invoices#set_unpaid', as: :invoice_paid, via: [:delete]
match '/tocat/invoices/:id/orders' => 'invoices#deattach_order', as: :invoice_orders, via: [:delete]
match '/tocat/payment' => 'tocat#new_payment', as: :payment, via: [:get]
match '/tocat/payment' => 'tocat#create_payment', as: :payment, via: [:post]
match '/tocat/bonus' => 'tocat#new_bonus', as: :bonus, via: [:get]
match '/tocat/bonus' => 'tocat#pay_bonus', as: :bonus, via: [:post]

match '/issues/:id/accepted' => 'tocat#toggle_accepted', as: :issue_accepted, via: [:post, :put]

match '/tocat/request_review' => 'tocat#request_review', :via => :put
match '/tocat/review_handler' => 'tocat#review_handler', :via => :put
