class Aji::Identity < ActiveRecord::Base
  has_many :accounts, :class_name => 'Aji::ExternalAccount'
  has_one :user, :class_name => 'Aji::User'
end
