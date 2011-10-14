require_relative '../aji'

def fix_nil_authors count
  Aji.log "Fixing #{count} populated videos with nil authors..."
  done = 0
  Aji::Video.find_each do |v|
    break if done > count
    if v.has_nil_author?
      Resque.enqueue Aji::Queues::FixPopulatedVideo, v.id
      puts "Video[#{v.id}] enqueued"
      done += 1
    end
  end
end
