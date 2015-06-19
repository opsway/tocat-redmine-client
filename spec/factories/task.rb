FactoryGirl.define do
  factory :task, class: TocatTicket do
    sequence(:id)
    sequence(:external_id) { |r| "task_#{r}" }
    budget Random.rand(10)
    sequence(:paid) { |r| r%2 == 0 ? true : false }
    sequence(:accepted) { |r| r%2 != 0 ? true : false }
    ignore do
      association :resolver_record, strategy: :build, factory: :resolver
    end
    resolver {{name: resolver_record.name, id: resolver_record.id}}
    orders []
    factory :task_with_orders, class: TocatTicket do
      orders {[{name: "Order #{Random.rand}"}, {name: "Order #{Random.rand}"}]}
    end
    task_orders []
    factory :task_with_task_orders, class: TocatTicket do
      task_orders {
        {budget:[{order_id:Random.rand(10),budget:Random.rand},
                 {order_id:Random.rand(10),budget:Random.rand},
                 {order_id:Random.rand(10),budget:Random.rand}]}
      }
    end
  end

  factory :invalid_task, class: TocatTicket do
    sequence(:id)
    sequence(:external_id) { |r| "task_#{r}" }
  end
end
