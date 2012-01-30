require_relative '../aji'
include Aji

first_arg = ARGV.first
n = if first_arg.to_i.to_s == first_arg
      first_arg.to_i
    else
      1
    end
period = n.days.ago..Time.now
accounts = Account::Facebook.where(:updated_at => period);

puts "Current we have: #{Aji.redis.scard("EmailCollectors::Facebook")} emails"
accounts.map &:collect_email
puts "    Now we have: #{Aji.redis.scard("EmailCollectors::Facebook")} emails"
