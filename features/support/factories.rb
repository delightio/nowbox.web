FactoryGirl.define do
  factory :user, :class => Aji::User do
    sequence(:first_name) { |n| "User#{n}" }
    sequence(:last_name) { |n| "Surname#{n}" }
    email { "#{first_name}@#{last_name}.com".downcase }
  end

  factory :twitter_account, :class => Aji::Account::Twitter do
    sequence(:uid) { |n| n.to_s }
    sequence(:username) { |n| "TwitterUser#{n}" }
  end

  factory :twitter_channel, :class => Aji::Channel::TwitterAccount do
    account Factory :twitter_account
  end
end
