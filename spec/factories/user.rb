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

  factory :real_user, class: User do
    status 1
    last_login_on '2006-07-19 22:42:15 +02:00'
    language 'en'
    # password = jsmith
    salt '67eb4732624d5a7753dcea7ce0bb7d7d'
    hashed_password 'bfbe06043353a677d0215b26a5800d128d5413bc'
    admin false
    lastname 'Smith'
    firstname 'John'
    login 'jsmith'
    type User
    sequence(:mail) { |r| "test#{r}@abc.com" }
    sequence(:country_code)
    mobile 1234567890
  end
end