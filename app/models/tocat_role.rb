class TocatRole < ActiveRecord::Base
  unloadable
  serialize :permissions
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30

  has_many :tocat_user_roles, class_name: "TocatUserRole"
  has_many :principals, through: :tocat_user_roles, class_name: "Principal"

  acts_as_list

  def self.permissions #load from config? and add issues
    return [:create_orders, :show_orders, :edit_orders, :destroy_orders, :split_orders, :complete_orders,
            :create_invoices, :show_invoices, :edit_invoices, :destroy_invoices, :paid_invoices,
            :modify_accepted, :modify_resolver, :modify_budgets, :show_tocat_page, :show_budgets
          ]
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
