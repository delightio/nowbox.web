class Aji::Identity < ActiveRecord::Base
  has_many :accounts, :class_name => 'Aji::Account'
  has_one :user, :class_name => 'Aji::User'

  # Identity is a model which associates multiple user accounts with the same
  # person or corporation. At this time, the only way for this to happen is for
  # a user to log in and authorize us for multiple services (such as Twitter,
  # Facebook, and Youtube)

  # Identities are created whenever a user logs in. Down the road they'll also
  # be created by authors and others using our backend products.
end
