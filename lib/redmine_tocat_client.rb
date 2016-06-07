Rails.configuration.to_prepare do
  # all internal files MUST be described here
  # classes
  require 'api/models/auth'
  require 'api/models/ticket'
  require 'api/models/order'
  require 'api/models/invoice'
  require 'api/models/tocat_user'
  require 'api/models/tocat_team'
  require 'api/models/transaction'
  require 'api/models/server_role'
  require 'api/models/tocat_balance_transfer'
  require 'api/models/tocat_transfer_request'
  require 'api/models/payment_request'
  # patches
  require 'api/patches/active_resource_errors'
  require 'patches/user'
  require 'patches/users_helper'
  require 'patches/issues_controller'
  require 'patches/group'
  require 'patches/issue'

  # hooks
  require 'hooks/view_issue_hook'


end

module RedmineTocatClient
  def self.settings
    if Setting[:plugin_redmine_tocat_client].blank?
      {}
    else
      Setting[:plugin_redmine_tocat_client]
    end
  end
end
