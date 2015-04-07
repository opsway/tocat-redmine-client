class CreateTocatUserRoles < ActiveRecord::Migration
  def change
    create_table :tocat_user_roles do |t|
      t.integer :principal_id, null: false
      t.integer :tocat_role_id, null: false
      t.integer :creator_id, null: false
    end
  end
end
