require 'plugin_helper'

RSpec.feature "Widget management", :type => :feature do
  before(:all) do
    user = FactoryGirl.create(:real_user)
    log_user(user.login, 'jsmith')
  end

  scenario "User should see invoice index page" do
    visit "/tocat/invoices"

    expect(page).to have_text("Invoices")
  end
end