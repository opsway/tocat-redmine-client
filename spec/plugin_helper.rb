require 'rails_helper'
require 'support/helpers.rb'

RSpec.configure do |config|
  config.include Helpers
  config.include FactoryGirl::Syntax::Methods
end

FactoryGirl.definition_file_paths.push(File.join(Rails.root, 'plugins/redmine_tocat_client/spec/factories'))
FactoryGirl.find_definitions