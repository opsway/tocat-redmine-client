class CreateTocatRoles < ActiveRecord::Migration
  def change
    create_table :tocat_roles do |t|
      t.string :name, null: false
      t.text :permissions
      t.integer :position, null: false, default: 1
    end
  end
end
