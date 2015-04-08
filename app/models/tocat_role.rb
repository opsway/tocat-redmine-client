class TocatRole < ActiveRecord::Base
  unloadable
  serialize :permissions
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30

  has_many :tocat_user_roles, class_name: "TocatUserRole"
  has_many :users, through: :tocat_user_roles, class_name: "User"

  acts_as_list

  def self.permissions #load from config? and add issues
    data = {}
    data[:orders] = [:create_orders, :show_orders, :edit_orders, :destroy_orders, :complete_orders]
    data[:invoices] = [:create_invoices, :show_invoices, :destroy_invoices, :paid_invoices]
    data[:issues] = [:modify_accepted, :modify_resolver, :modify_budgets, :show_budgets, :show_issues]
    data[:dashboard] = [:show_tocat_page, :has_protected_page, :can_see_public_pages, :is_admin]
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
