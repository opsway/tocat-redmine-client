FactoryGirl.define do
  factory :activity, class: Hash do
    sequence(:id)
    key 'invoice.paid_update'
  end
end

