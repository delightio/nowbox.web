class Aji::Identity < ActiveRecord::Base
  has_many :accounts, :class_name => 'Aji::Account'
  has_one :user, :class_name => 'Aji::User'
end
