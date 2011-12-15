include Aji

chs = {}
chs.merge!  "Comedy" => ["funnyordie", "collegehumor", "BREAK", "failblog"]
chs.merge!  "Entertainment" => ["eentertainment", "TMZ", "HollywoodTV"]
chs.merge!  "News" => ["AssociatedPress", "RussiaToday", "CNN", "FoxNewsChannel"]
chs.merge!  "Games" => ["machinima", "G4TV", "pcgamer", "ignentertainment"]
chs.merge!  "Education" => ["khanacademy", "stanforduniversity", "mit"]
chs.merge!  "Sports" => ["HBOsports", "FoxSports"]
chs.merge!  "Tech" => ["TechCrunch", "GoogleTechTalks"]
chs.merge!  "Autos" => ["topgear", "motortrend"]
chs.merge!  "Travel" => ["travelchannelTV", "lonelyplanet"]
chs.merge!  "Howto" => ["homedepot", "ehow", "expertvillage"]
chs.merge!  "Music" => ["karmincovers", "pomplamoosemusic"]
chs.merge!  "Trailers" => ["trailers"]

chs.each do |category_title, channel_names|
	puts "#{category_title}: #{channel_names}"
	category = Category.find_by_title category_title
	if category.nil?
		puts "Couldn't find category: #{category_title}"
		next
	end

	channel_names.each do |name|
		uid = name.downcase
		account = Account::Youtube.find_by_uid uid
		if account.nil?
			puts "Couldn't find YouTube account: #{name}"
			account = Account::Youtube.find_or_create_by_lower_uid uid
			account.to_channel.background_refresh_content
		end

		puts "  added: #{name}"
		category.onboard_channel_ids << account.to_channel.id
	end
end