# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :jp_address_zipcode, :class => 'JpAddress::Zipcode' do
    zip        "5330033"
    prefecture "大阪府"
    city       "大阪市東淀川区"
    town       "東中島"
  end
end
