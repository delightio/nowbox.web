Fabricate :user do
  email { sequence(:email) { |i| "user#{i}@sample.com" } }
  first_name { sequence(:first_name) { |i| "Steven! #{i}" } }
  last_name { sequence(:last_name) { |i| "Surname #{i}" } }
end
