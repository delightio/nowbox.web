module Aji
  class Queues::RemoveSpammer
    @queue = :remove_spammer

    def self.perform spammer_id
      spammer = Account.find spammer_id
      spammer.mark_spammer
    end
  end
end
