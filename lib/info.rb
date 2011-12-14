module Aji
  module Info
    def for_device device
      case device
      when "ipad"
        {
          :current_version => "1.0.23",
          :minimum_version => "1.0.21",
          :link => { :rel => "latest",
                     :url => "http://tflig.ht/rwxYEk" },
          :links => [{ :rel => "latest",
                     :url => "http://tflig.ht/rwxYEk" },
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
