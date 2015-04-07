class TocatUserRole < ActiveRecord::Base
  unloadable
  belongs_to :tocat_role, class_name: 'TocatRole'
  belongs_to :principal, class_name: 'Principal'
end
