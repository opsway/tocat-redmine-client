class TocatRole < ActiveRecord::Base
  unloadable
  serialize :permissions
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30

  has_many :tocat_user_roles, class_name: "TocatUserRole"
  has_many :users, through: :tocat_user_roles, class_name: "User"

  acts_as_list

  def self.check_path(request)
    paths = {}

    paths[:orders] = {}
    paths[:orders][:create] = :create_orders
    paths[:orders][:new] = :create_orders
    paths[:orders][:create_suborder] = :create_orders
    paths[:orders][:show] = :show_orders
    paths[:orders][:index] = :show_orders
    paths[:orders][:invoices] = :create_invoices
    paths[:orders][:set_invoice] = :create_invoices
    paths[:orders][:delete_invoice] = :create_invoices
    paths[:orders][:edit] = :edit_orders
    paths[:orders][:update] = :edit_orders
    paths[:orders][:destroy] = :destroy_orders
    paths[:orders][:toggle_complete] = :complete_orders
    paths[:orders][:toggle_uncomplete] = :uncomplete_orders
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
    paths[:tocat][:new_bonus] = :create_transactions
    paths[:tocat][:pay_bonus] = :create_transactions
    paths[:tocat][:request_review] = :can_request_review
    paths[:tocat][:review_handler] = :can_review_task
    paths[:tocat][:set_expenses] = :set_expenses
    paths[:tocat][:remove_expenses] = :remove_expenses

    paths[:tickets] = {}
    paths[:tickets][:index] = :show_issues

    paths[:status] = {}
    paths[:status][:status] = :show_status_page
    paths[:status][:checked] = :mark_alerts_as_checked

    #users
    paths[:tocat_users] = {}
    paths[:tocat_users][:index] = :show_issues
    paths[:tocat_users][:new] = :create_user
    paths[:tocat_users][:create] = :create_user
    paths[:tocat_users][:edit] = :update_user
    paths[:tocat_users][:update] = :update_user
    paths[:tocat_users][:destroy] = :deactivate_user
    paths[:tocat_users][:makeactive] = :activate_user

    #transactions
    paths[:transactions] = {}
    paths[:transactions][:index] = :show_transactions
    #paths[:transactions][:create] = :create_transactions
    paths[:transactions][:new] = :create_transactions
    paths[:transactions][:edit] = :create_transactions
    return false unless paths[request[:controller].to_sym].present?
    return false unless paths[request[:controller].to_sym][request[:action].to_sym].present?
    return false unless User.current.tocat_allowed_to?(paths[request[:controller].to_sym][request[:action].to_sym])
    true
  end

  def self.permissions #load from config?
    data = {}
    data[:orders] = [:create_orders, :show_orders, :edit_orders, :destroy_orders, :complete_orders, :uncomplete_orders, :set_internal_orders, :remove_internal_orders, :show_commission, :update_commission]
    data[:invoices] = [:create_invoices, :show_invoices, :destroy_invoices, :paid_invoices]
    data[:issues] = [:modify_accepted, :modify_resolver, :modify_budgets, :show_budgets, :show_issues, :show_aggregated_info, :can_request_review, :can_review_task, :set_expenses, :remove_expenses]
    data[:transactions] = [:show_transactions, :create_transactions]
    data[:dashboard] = [:show_tocat_page, :has_protected_page, :can_see_public_pages, :is_admin, :show_status_page, :mark_alerts_as_checked, :show_activity_feed]
    data[:users] = [:create_user,:update_user, :activate_user, :deactivate_user]
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
