require_relative '../aji'
include Aji

first_arg = ARGV.first
n = if first_arg.to_i.to_s == first_arg
      first_arg.to_i
    else
      1
    end
period = n.days.ago..Time.now

c = 0
puts "Current we have: #{Aji.redis.scard("EmailCollectors::Facebook")} emails"
Account::Facebook.find_each(:conditions => {:updated_at => period}) do |a|
  a.collect_email
  c += 1 if a.authorized?
end;
puts "    Now we have: #{Aji.redis.scard("EmailCollectors::Facebook")} emails from #{c} authorized accounts"
