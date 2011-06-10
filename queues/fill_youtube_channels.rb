module Aji
  module Queues
    # This class stores a list of interesting topic channels and adds them to
    # our dataset. The first time it runs will be excruciating and then it will
    # only pick up new videos. It should run every week or so at first since
    # it is not short circuiting. Once it is we can check for new videos more
    # often.
    class FillYoutubeChannels
      # Specify a class attribute `queue` which resque uses for job control.
      @@queue = :fill_youtube_channels

      def self.perform
        channels = {
          "TED" => %w{ TEDxTalks tedtalksdirector },
          "Sports" => %w{ nba nhlvideo CBSSports foxsports ESPN } ,
          "Cars" =>   %w{ AstonMartin BMW ferrariworld TopGear motortrend
            AutomotiveTv autoblogger },
          "Trailers" => %w{ LionsgateLIVE SonyPictures MARVEL },
          #"music" => %w{VEVO BritneySpearsVEVO LadyGagaVEVO JustinBieberVEVO
          #RihannaVEVO keshaVEVO Maroon5VEVO ColdplayVEVO AdamLambertVEVO},
          "News" => %w{AssociatedPress CNN PBSNewsHour BBC CBS},
          "Funny" => %w{ Break cheezburger failblog},
          "Kids" =>  %w{ EricHermanMusic ArthurTV1996 pingu TheGiggleBellies
            RajshriKids GoldenNickelodeon SockeyeMedia SuperAwesomeSylvia },
          "Science" => %w{ NationalGeographic NatGeoWiLd discoverynetworks
            AnimalPlanetTV ScienceChannel}
        }

        channels.each do |name, authors|
          # Load or create Youtube account for each author.
          accounts = Array.new
          authors.each do |a|
            accounts << ExternalAccount::Youtube.
              find_or_create_by_uid_and_provider(a, :youtube)
          end
          # Create Youtube account channel.
          channel = Channels::YoutubeAccount.find_or_create_by_title(channel,
            :accounts => accounts)
          # Add the channel to a seperate queue to be populated.
          Resqueue.enqueue PopulateChannel channel.id
        end
      end
    end
  end
end
