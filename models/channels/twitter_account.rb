module Aji
  class Channels::TwitterAccount < Channel
    has_one :account, :class_name => 'Aji::ExternalAccounts::Twitter'

  end
end
