module Aji
  module Info
    def for_device device
      case device
      when "ipad"
        {
          :current_version => "2.0",
          :minimum_version => "2.0",
          :link => { :rel => "latest",
                     :url => "http://nowbox.com" },
          :links => [{ :rel => "latest",
                     :url => "http://nowbox.com" },
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
