# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match '/tocat' => 'tocat#my_tocat', as: :my_tocat, via: [:get]
#match '/tocat/invoices' => 'tocat#invoices', as: :invoices, via: [:get]
#match '/tocat/invoices/:invoice_id' => 'tocat#show_invoice', as: :show_invoice, via: [:get]

resources :orders, path: '/tocat/orders'
resources :invoices, path: '/tocat/invoices'
match '/tocat/new_suborder' => 'orders#create_suborder', as: :suborder, via: [:post, :put]
match '/tocat/budget' => 'tocat#budget_dialog', via: :get
match '/tocat/budget' => 'tocat#save_budget_dialog', via: :post
match '/tocat/invoices/:id/paid' => 'invoices#set_paid', as: :invoice_paid, via: [:post, :put]
match '/tocat/invoices/:id/paid' => 'invoices#set_unpaid', as: :invoice_paid, via: [:delete]
