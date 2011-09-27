require_relative '../aji'

def reindex offset=0
  [Aji::Account].each do |klass|
    index = 0
    updated = 0

    start_time = Time.now
    puts "#{klass} has #{klass.count} records."
    klass.find_each(:start=>offset) do |m|
      index += 1
      if m.searchable?
        m.update_tank_indexes_if_searchable
        updated += 1
      end
      puts " #{updated} updated at index #{index}" if index % 100 == 0
    end

    puts
    puts "*** Total updated: #{updated} in #{Time.now-start_time} s ***"
  end
end