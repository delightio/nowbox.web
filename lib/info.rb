module Aji
  module Info
    def for_device device
      case device
      when "ipad"
        {
          :current_version => "1.4.3",
          :minimum_version => "1.4.3",
          :link => { :rel => "latest",
                     :url => "http://itunes.apple.com/app/nowbox/id464416202?mt=8&uo=4" },
          :links => [{ :rel => "latest",
                     :url => "http://itunes.apple.com/app/nowbox/id464416202?mt=8&uo=4" },
                     { :rel => "ratings",
                       :url => "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=464416202" }]

        }
      else
        raise Aji::Error, "Unknown device type #{device}"
      end
    end
    module_function :for_device
  end
end
