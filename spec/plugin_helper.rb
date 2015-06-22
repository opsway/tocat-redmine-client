require 'rails_helper'
require 'support/helpers.rb'
require 'capybara/rails'
require 'capybara/rspec'


RSpec.configure do |config|
  config.include Helpers
  config.include FactoryGirl::Syntax::Methods
  config.infer_spec_type_from_file_location!
end

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

FactoryGirl.definition_file_paths.push(File.join(Rails.root, 'plugins/redmine_tocat_client/spec/factories'))
FactoryGirl.find_definitions