require_relative '../aji'
include Aji
def drop_all_tables confirm
  if confirm!='1234'
    puts "Please pass in confirmation code of '1234' in string to confirm deletion"
    puts "Returning wiht no deletion on db"
    return
  end
  ActiveRecord::Base.establish_connection conf['DATABASE']
  ActiveRecord::Base.connection.tables.each do |table|
    print "droping table: #{table}... "
    ActiveRecord::Base.connection.drop_table table
    puts "done"
  end
end
