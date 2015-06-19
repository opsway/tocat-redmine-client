FactoryGirl.define do
  factory :team, class: TocatTeam do
    sequence(:id)
    sequence(:name) { |r| "Team#{r}" }
  end
end
