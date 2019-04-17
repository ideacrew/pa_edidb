FactoryGirl.define do
  factory :member do
    sequence(:hbx_member_id) {|n| "#{n}" }
    gender 'female'
    sequence(:ssn, 100000000) { |n| "#{n}" }
    dob { Date.parse("#{rand(1..28)}-#{rand(1..12)}-#{rand(1910..2000)}") }
  end
end
