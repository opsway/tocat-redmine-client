class RenamePrincipalToUserInTocatUserRoles < ActiveRecord::Migration
  def change
    rename_column :tocat_user_roles, :principal_id, :user_id
  end
end
