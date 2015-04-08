class TocatUserRole < ActiveRecord::Base
  unloadable
  belongs_to :tocat_role, class_name: 'TocatRole'
  belongs_to :user, class_name: 'User'
end
