require_relative '../aji'
include Aji

class Stats
  def self.group_by_occurance values, key, n
    grouped = values.all.map(&key).group_by{|g| g}
    sorted = grouped.sort { |x,y| y.last.count <=> x.last.count }
    formatted = sorted.map {|h| { h.first => h.last.count } }.first(n)
  end

  def self.print description, klass, stats
    puts description
    stats.each do |h|
      oid = h.keys.first
      count = h.values.first
      o = klass.find oid
      puts " #{count.to_s.rjust(4)} | #{o.to_s}"
    end
    puts
  end

  def self.print_all period
    Stats.print "Most popular videos:", Video, Video.most_popular(period)
    Stats.print "Most shared videos:", Video, Video.most_shared(period)

    Stats.print "Most subscribed channels:", Channel, Channel.most_subscribed(period)
    Stats.print "Most unsubscribed channels:", Channel, Channel.most_unsubscribed(period)

    Stats.print "Most active users:", User, User.most_active(period, 20)
  end
end

class Video
  def self.most_popular period, n=10
    viewed = Event.where(:created_at => period, :action => :view)
    Stats.group_by_occurance viewed, :video_id, n
  end

  def self.most_shared period, n=10
    viewed = Event.where(:created_at => period, :action => :share)
    Stats.group_by_occurance viewed, :video_id, n
  end

  def to_s; "#{id.to_s.rjust(8)} #{title}" end
end

class Channel
  def self.most_subscribed period, n=10
    subscribed = Event.where(:created_at => period, :action => :subscribe)
    Stats.group_by_occurance subscribed, :channel_id, n
  end

  def self.most_unsubscribed period, n=10
    unsubscribed = Event.where(:created_at => period, :action => :unsubscribe)
    Stats.group_by_occurance unsubscribed, :channel_id, n
  end

  def to_s; "#{id.to_s.rjust(8)} #{title} in #{categories.first.try(:title)}"; end
end

class User
  def self.most_active period, n=10
    events = Event.where(:created_at => period)
    Stats.group_by_occurance events, :user_id, n
  end

  def time_on_app period=1.days.ago..Time.now
    viewed = Event.where(:created_at => period, :action => :view, :user_id => id)
    total = 0
    viewed.each do | event |
      duration = event.video_elapsed - event.video_start
      duration = 0 if duration < 0
      total += duration unless duration > event.video.duration
    end
    Integer total/60
  end

  def to_s
    info = [].tap do |names|
      names << "t: #{twitter_account.username}" if twitter_account
      names << "f: #{facebook_account.username}" if facebook_account
    end
    "#{id.to_s.rjust(8)}, #{time_on_app} m, #{info.join(", ")}"
  end
end

period = 1.days.ago..Time.now

Stats.print_all period


binding.pry if ARGV.first == '-i'