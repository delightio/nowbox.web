require_relative '../aji'
include Aji

limit = 50
n = (ARGV.first || '1').to_i

puts "video_elapsed > video.duration"
Event.where(:created_at => n.days.ago..Time.now, :action => :view).
  order('video_elapsed DESC').limit(limit).each_with_index do |e, index|
    if e.video_elapsed > e.video.duration + 1.0
      puts "#{index}  #{e}"
      # e.destroy
    end
  end;
puts

puts "video_elapsed < 0"
Event.where(:created_at => n.days.ago..Time.now, :action => :view).
  order('video_elapsed ASC').limit(limit).each_with_index do |e, index|
    if e.video_elapsed < 0
      puts "#{index}  #{e}"
      # e.destroy
    end
  end;
puts

puts "video_start > video.duration"
Event.where(:created_at => n.days.ago..Time.now, :action => :view).
  order('video_start DESC').limit(limit).each_with_index do |e, index|
    if e.video_start > e.video.duration + 1.0
      puts "#{index}  #{e}"
      # e.destroy
    end
  end;
puts

puts "video_start < 0"
Event.where(:created_at => n.days.ago..Time.now, :action => :view).
  order('video_start ASC').limit(limit).each_with_index do |e, index|
    if e.video_start < 0
      puts "#{index}  #{e}"
      # e.destroy
    end
  end;
