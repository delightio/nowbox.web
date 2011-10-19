require_relative '../aji'

# featured_by_title = %w(Comedy News Games Sports Trailers Music Entertainment Film Tech Education Travel Howto Autos )
# Aji::Category.set_featured featured_by_title

# featured_by_title = %w( NowComedy NowNews NowPopular freddiew )
# Aji::Channel.set_featured featured_by_title

module Aji

  default_regions =  [
    { :region => Region.en,
      :channel_titles => %w( NowComedy NowNews NowPopular freddiew ) },
    { :region => Region.ko,
      :channel_titles => %w(SMTOWN jypentertainment YGEntertainment sment wondergirls 2pm 2am missA 2NE1 OfficialSe7en) }]

  default_regions.each do | h |
    region = h[:region]
    titles = h[:channel_titles]

    puts "Processing #{region.inspect}..."
    titles.each do |title|
      channel = Channel.find_by_title title
      if channel.nil?
        # Go out and find create new channel
        q = title
        account = Account::Youtube.new :uid => q
        # Search db again just in case the account wasn't indexed for
        # other reasons, e.g., not enough content videos
        if account.existing?
          account = Account::Youtube.find_or_create_by_lower_uid q
          channel = account.to_channel
        end
      end
      puts "  Adding #{title}. (Channel[#{channel.id}])..."
      region.feature_channel channel unless channel.nil?
      sleep 1
    end
  end

end