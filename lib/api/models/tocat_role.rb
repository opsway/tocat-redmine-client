class TocatRole < ActiveResource::Base
  unloadable
  include AuthTocat
  self.site = RedmineTocatClient.settings[:host]
  self.collection_name = 'tocat_roles'
  self.element_name = 'tocat_role'
  add_response_method :http_response
  #serialize :permissions
  validates_presence_of :name
  validates_length_of :name, :maximum => 30

  def self.check_path(request)
    paths = {}

    paths[:orders] = {}
    paths[:orders][:create] = :create_orders
    paths[:orders][:new] = :create_orders
    paths[:orders][:create_suborder] = :create_orders
    paths[:orders][:show] = :show_orders
    paths[:orders][:csv] = :show_orders
    paths[:orders][:index] = :show_orders
    paths[:orders][:invoices] = :create_invoices
    paths[:orders][:set_invoice] = :create_invoices
    paths[:orders][:delete_invoice] = :create_invoices
    paths[:orders][:delete_task] = :delete_task
    paths[:orders][:edit] = :edit_orders
    paths[:orders][:update] = :edit_orders
    paths[:orders][:destroy] = :destroy_orders
    paths[:orders][:toggle_complete] = :complete_orders
    paths[:orders][:set_reseller] = :set_reseller_orders
    paths[:orders][:unset_reseller] = :unset_reseller_orders
    paths[:orders][:set_internal] = :set_internal_orders
    paths[:orders][:remove_internal] = :remove_internal_orders
    paths[:orders][:commission] = :update_commission

    paths[:invoices] = {}
    paths[:invoices][:create] = :create_invoices
    paths[:invoices][:new] = :create_invoices
    paths[:invoices][:show] = :show_invoices
    paths[:invoices][:index] = :show_invoices
    paths[:invoices][:destroy] = :destroy_invoices
    paths[:invoices][:set_paid] = :paid_invoices
    paths[:invoices][:set_unpaid] = :paid_invoices
    paths[:invoices][:deattach_order] = :create_invoices
    paths[:invoices][:attach_order] = :create_invoices
    paths[:invoices][:edit] = :edit_orders
    paths[:invoices][:update] = :edit_orders

    paths[:tocat] = {}
    paths[:tocat][:toggle_accepted] = :modify_accepted
    paths[:tocat][:update_resolver] = :modify_resolver
    paths[:tocat][:budget_dialog] = :modify_budgets
    paths[:tocat][:save_budget_dialog] = :modify_budgets
    paths[:tocat][:delete_budget] = :modify_budgets
    paths[:tocat][:my_tocat] = :show_tocat_page
    paths[:tocat][:new_payment] = :create_transactions
    paths[:tocat][:create_payment] = :create_transactions
    paths[:tocat][:tocat_chart_data] = :show_tocat_page
    paths[:tocat][:request_review] = :can_request_review
    paths[:tocat][:review_handler] = :can_review_task
    paths[:tocat][:set_expenses] = :set_expenses
    paths[:tocat][:remove_expenses] = :remove_expenses
    paths[:tocat][:create_salary_checkin] = :correct_balance_salary_check
    paths[:tocat][:new_salary_checkin] = :correct_balance_salary_check
    paths[:tocat][:new_correction] = :correct_balance_salary_check
    paths[:tocat][:create_correction] = :correct_balance_salary_check

    paths[:tickets] = {}
    paths[:tickets][:index] = :show_issues

    paths[:status] = {}
    paths[:status][:status] = :show_status_page
    paths[:status][:checked] = :mark_alerts_as_checked

    #timelogs
    paths[:timelogs] = {}
    paths[:timelogs][:index] = :show_timelogs
    paths[:timelogs][:create] = :create_timelogs
    paths[:timelogs][:issues_summary] = :get_issues_summary

    #users
    paths[:tocat_users] = {}
    paths[:tocat_users][:index] = :show_issues
    paths[:tocat_users][:new] = :create_user
    paths[:tocat_users][:create] = :create_user
    paths[:tocat_users][:edit] = :update_user
    paths[:tocat_users][:update] = :update_user
    paths[:tocat_users][:destroy] = :deactivate_user
    paths[:tocat_users][:makeactive] = :activate_user
    paths[:tocat_users][:csv] = :create_user

    #daily_rates_history
    paths[:history_of_change_daily_rates] = {}
    paths[:history_of_change_daily_rates][:index] = :show_rates_history

    #teams
    paths[:tocat_teams] = {}
    paths[:tocat_teams][:index] = :show_issues
    paths[:tocat_teams][:new] = :create_team
    paths[:tocat_teams][:create] = :create_team
    paths[:tocat_teams][:edit] = :update_team
    paths[:tocat_teams][:update] = :update_team
    paths[:tocat_teams][:destroy] = :deactivate_team
    paths[:tocat_teams][:makeactive] = :activate_team
    
    #balance transfers
    paths[:internal_payments] = {}
    paths[:internal_payments][:index] = :view_transfers
    paths[:internal_payments][:new] = :create_transfer
    paths[:internal_payments][:create] = :create_transfer
    paths[:internal_payments][:show] = :view_transfers
    #transfer requests
    paths[:internal_invoices] = {}
    paths[:internal_invoices][:index] = :view_transfers
    paths[:internal_invoices][:new] = :create_transfer
    paths[:internal_invoices][:edit] = :create_transfer
    paths[:internal_invoices][:update] = :create_transfer
    paths[:internal_invoices][:destroy] = :create_transfer
    paths[:internal_invoices][:create] = :create_transfer
    paths[:internal_invoices][:show] = :view_transfers
    paths[:internal_invoices][:pay] = :create_transfer
    paths[:internal_invoices][:new_withdraw] = :create_transfer
    paths[:internal_invoices][:create_withdraw] = :create_transfer

    #payment requests
    paths[:external_payments] = {}
    paths[:external_payments][:index]   = :view_payment_requests
    paths[:external_payments][:show]    = :view_payment_requests
    paths[:external_payments][:new]     = :create_payment_request
    paths[:external_payments][:edit]    = :edit_payment_request 
    paths[:external_payments][:update]  = :edit_payment_request
    paths[:external_payments][:create]  = :create_payment_request
    paths[:external_payments][:complete]= :complete_payment_request
    paths[:external_payments][:cancel]  = :cancel_payment_request

    #accounts
    paths[:accounts] = {}
    paths[:accounts][:new]     = :create_account
    paths[:accounts][:index]   = :view_all_accounts
    paths[:accounts][:show]    = :view_all_accounts
    paths[:accounts][:new]     = :create_account
    paths[:accounts][:edit]    = :edit_account
    paths[:accounts][:update]  = :edit_account
    paths[:accounts][:create]  = :create_account
    paths[:accounts][:add_user]  = :edit_account
    paths[:accounts][:remove_user]  = :edit_account

    #transactions
    paths[:transactions] = {}
    paths[:transactions][:index] = :show_transactions
    return false unless paths[request[:controller].to_sym].present?
    return false unless paths[request[:controller].to_sym][request[:action].to_sym].present?
    return false unless User.current.tocat_allowed_to?(paths[request[:controller].to_sym][request[:action].to_sym])
    true
  end

  def self.permissions #load from config?
    data = {}
    data[:orders] = [:create_orders, :show_orders, :edit_orders, :destroy_orders, :complete_orders, :set_internal_orders, :remove_internal_orders, :show_commission, :update_commission, :set_reseller_orders, :unset_reseller_orders, :delete_task]
    data[:invoices] = [:create_invoices, :show_invoices, :destroy_invoices, :paid_invoices, :view_all_invoices]
    data[:issues] = [:modify_accepted, :modify_resolver, :modify_budgets, :show_budgets, :show_issues, :show_aggregated_info, :can_request_review, :can_review_task, :set_expenses, :remove_expenses]
    data[:transactions] = [:show_transactions, :create_transactions]
    data[:dashboard] = [:show_tocat_page, :has_protected_page, :can_see_public_pages, :is_admin, :show_status_page, :mark_alerts_as_checked, :show_activity_feed]
    data[:users] = [:create_user, :update_user, :activate_user, :deactivate_user, :correct_balance_salary_check]
    data[:history_of_change_daily_rates] = [:show_rates_history]
    data[:teams] = [:create_team, :update_team, :activate_team, :deactivate_team]
    data[:internal_payments] = [:view_transfers, :create_transfer, :view_all_transfer_requests]
    data[:external_payments] = [:create_payment_request, :cancel_payment_request, :complete_payment_request, :view_payment_requests, :view_all_payment_requests]
    data[:accounts] = [:create_account, :edit_account, :view_linked_accounts, :view_all_accounts]
    data[:timelogs] = [:show_timelogs, :create_timelogs, :get_issues_summary]
    return data
  end

  def permissions=(perms)
    perms = perms.collect {|p| p.to_sym unless p.blank? }.compact.uniq if perms
    write_attribute(:permissions, perms)
  end

  def add_permission!(*perms)
    self.permissions = [] unless permissions.is_a?(Array)

    permissions_will_change!
    perms.each do |p|
      p = p.to_sym
      permissions << p unless permissions.include?(p)
    end
    save!
  end

  def remove_permission!(*perms)
    return unless permissions.is_a?(Array)
    permissions_will_change!
    perms.each { |p| permissions.delete(p.to_sym) }
    save!
  end

  def has_permission?(perm)
    !permissions.nil? && permissions.include?(perm.to_sym)
  end


  def allowed_to?(action)
    allowed_permissions.include? action
  end

  private

  def allowed_permissions
    @allowed_permissions ||= permissions
  end

end
