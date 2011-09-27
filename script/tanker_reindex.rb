require_relative '../aji'

[Aji::Account].each do |klass|
  index = 0
  updated = 0

  start = Time.now
  puts "#{klass} has #{klass.count} records."
  klass.find_each do |m|
    index += 1
    if m.searchable?
      m.update_tank_indexes
      updated += 1
    end
    puts " #{updated} updated at index #{index}" if index % 100 == 0
  end

  puts
  puts "*** Total updated: #{updated} in #{Time.now-start} s ***"
end