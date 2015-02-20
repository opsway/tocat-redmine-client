# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match '/tocat/orders/:order_id' => 'tocat#show_order', as: :tocat_order, via: [:get]
match '/tocat/orders/:order_id' => 'tocat#update_order', as: :update_order, via: [:post, :put]
match '/tocat/orders' => 'tocat#orders', as: :orders, via: [:get]
match '/tocat' => 'tocat#my_tocat', as: :my_tocat, via: [:get]
match '/tocat/invoices' => 'tocat#invoices', as: :invoices, via: [:get]
match '/tocat/invoices/:invoice_id' => 'tocat#show_invoice', as: :show_invoice, via: [:get]
