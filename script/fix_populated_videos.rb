require_relative '../aji'

def fix_nil_authors count, offset=0
  Aji.log "Fixing #{count} populated videos with nil authors (offset: #{offset})..."
  done = 0
  new_offset = offset
  Aji::Video.find_each(:offset=>0) do |v|
    break if done > count
    if v.has_nil_author?
      Resque.enqueue Aji::Queues::FixPopulatedVideo, v.id
      puts "Video[#{v.id}] enqueued"
      done += 1
      new_offset = v.id
    end
  end
  new_offset
end
