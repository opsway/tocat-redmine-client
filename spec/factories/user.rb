FactoryGirl.define do
  factory :user, class: User do
    password '12345678'
    sequence(:firstname) { |r| "User_#{r}" }
    sequence(:lastname) { |r| "Test_#{r}" }
    sequence(:mail) { |r| "test#{r}@abc.com" }
    sequence(:country_code)
    mobile 1234567890
    sequence(:login) { |r| "usr_#{r}" }
  end

  factory :resolver, class: TocatUser do
    user { FactoryGirl.create(:user) }
    sequence(:id)
    name { "#{user.firstname} #{user.lastname}" }
  end
end
