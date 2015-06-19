FactoryGirl.define do
  factory :order, class: TocatOrder do
    sequence(:id)
    invoiced_budget Random.rand(100)
    allocatable_budget { invoiced_budget - 3 }
    free_budget { invoiced_budget - 8 }
    sequence(:name) { |r| "Order #{r}" }
    sequence(:paid) { |r| r%2 == 0 ? true : false }
    sequence(:completed) { |r| r%2 != 0 ? true : false }
    team {{name: "Team#{Random.rand(10)}", id: Random.rand(10)}}
    tasks []
    sub_orders []
  end
end
