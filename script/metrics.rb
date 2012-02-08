require_relative '../aji'
include Aji

class Stats
  @@launch_date = Time.local(2011,12,14) # give it one extra day

  def self.group_by_occurance_all values, key
    grouped = values.all.map(&key).group_by{|g| g}
    sorted = grouped.sort { |x,y| y.last.count <=> x.last.count }
    formatted = sorted.map {|h| { h.first => h.last.count } }
  end

  def self.group_by_occurance values, key, n
    group_by_occurance_all(values,key).first(n)
  end

  def self.print description, klass, stats
    puts description
    stats.each_with_index do |h,index|
      oid = h.keys.first
      count = h.values.first
      o = klass.find_by_id oid
      puts "#{(index+1).to_s.rjust(3)}.  #{count.to_s.rjust(4)} | #{o.to_s}" unless o.nil?
      puts "  #{klass}[#{oid}] not found" if o.nil?
    end
  end

  def self.print_all period
    Stats.print "Most active users:", User, User.most_active(period, 40)
    puts
    Stats.print "Least active users:", User, User.least_active(period, 40)
    puts

    Stats.print_video_events period
    puts
    Stats.print_channel_events period
    puts

    Stats.print_time_on_app period
    puts

    puts "Last 7 days"
    Stats.print_time_on_app 7.days.ago..Time.now
    puts

    puts "Since launch"
    Stats.print_time_on_app
  end

  def self.print_video_events period, n=10
    Event.video_actions.each do |action|
      events = Event.where :created_at => period, :action => action
      events_with_count = Stats.group_by_occurance events, :video_id, n
      Stats.print "#{events.count} #{action} events:", Video, events_with_count
      puts
    end
  end

  def self.print_channel_events period, n=10
    Event.channel_actions.each do |action|
      events = Event.where :created_at => period, :action => action
      events_with_count = Stats.group_by_occurance events, :channel_id, n
      Stats.print "#{events.count} #{action} events:", Channel, events_with_count
      puts
    end
  end

  def self.print_time_on_app period=@@launch_date..Time.now
    total = Event.where(:created_at => period, :action => :view).sum('video_elapsed')
    user_count = Event.where(:created_at => period, :action => :view).select('user_id').count(:distinct=>true)
    avg_mins = total / user_count / 60.0

    puts "Average time on App (#{period}) = %.2f m (#{total} s / #{user_count} users)" % avg_mins
    summary = [].tap do |summary|
      Event.video_actions.each do |action|
        summary << (
          {action => Event.where(:created_at=> period, :action => action).count})
      end
    end
    puts "  Video: #{summary.join ', '}"

    summary = [].tap do |summary|
      Event.channel_actions.each do |action|
        summary << (
          {action => Event.where(:created_at=> period, :action => action).count})
      end
    end
    puts "  Channel: #{summary.join ', '}"

    new_user_count = User.where(:created_at=>period).count
    puts "  User: new #{new_user_count}, returning #{user_count-new_user_count}"
  end

end

class Video
  def to_s; "#{id.to_s.rjust(8)} #{title}"; end
end

class Channel
  def to_s; "#{id.to_s.rjust(8)} #{title} in #{categories.first.try(:title)}"; end
end

class User
  def self.most_active period, n=10
    events = Event.where(:created_at => period)
    Stats.group_by_occurance events, :user_id, n
  end

  def self.least_active period, n=10
    events = Event.where(:created_at => period)
    Stats.group_by_occurance_all(events, :user_id).last(100).sample(n)
  end

  def youtube_account
    return nil if identity.accounts.empty?
    identity.accounts.select{|a| a.class == Account::Youtube }.first
  end

  def to_s period=1.days.ago..Time.now
    info = [].tap do |names|
      names << "yt: #{youtube_account.username}" if youtube_account
      names << "t: #{twitter_account.username}" if twitter_account
      names << "fb: #{facebook_account.username}, #{facebook_account.email}" if facebook_account
    end
    lifetime_minutes_on_app = minutes_on_app
    track_time_on_app lifetime_minutes_on_app * 60
    "#{id.to_s.rjust(8)}, #{(minutes_on_app period).to_s.rjust(3)} / #{lifetime_minutes_on_app.to_s.rjust(3)} m, #{events.count} events, #{subscribed_channel_ids.count} channels, #{info.join(", ")}"
  end
end

first_arg = ARGV.first
n = if first_arg.to_i.to_s == first_arg
      first_arg.to_i
    else
      1
    end
period = n.days.ago..Time.now

binding.pry if first_arg == '-i'

Stats.print_all period
