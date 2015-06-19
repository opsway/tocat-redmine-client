FactoryGirl.define do
  factory :invoice, class: TocatInvoice do
    sequence(:id)
    sequence(:external_id) { |n| "task_#{n}" }
    paid false
    links {{ href: "/invoice/#{self.id}", rel: "self" }}
  end
end
