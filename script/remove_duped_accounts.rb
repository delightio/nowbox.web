require_relative '../aji'

include Aji

duped_uids =
  Account::Youtube.select("LOWER(uid), COUNT(LOWER(uid))").
                  group("LOWER(uid) HAVING COUNT(LOWER(uid)) > 1").map do |a|
                                                              [a.lower, a.count]
                                                            end
puts "Fount #{duped_uids.count} duped ids"

duped_uids.each do |uid|
  duplicated_accounts = Account.where("LOWER(uid) = ?", uid).order(
    :created_at).all

  puts "Removing #{duplicated_accounts.size - 1} copies of Youtube[#{uid}]."

  duplicated_accounts.first.uid = duplicated_accounts.first.uid.downcase
  duplicated_accounts.first.save!

  duplicated_accounts[1..-1].each &:destroy
end

