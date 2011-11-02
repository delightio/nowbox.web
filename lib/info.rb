module Aji
  module Info
    def for_device device
      case device
      when "ipad"
        {
          :current_version => "1.0.14b10",
          :minimum_version => "1.0.12b1",
          :link => { :rel => "latest",
                     :url => "http://itunes.com/apps/googlesearch?" }
        }
      else
        raise Aji::Error, "Unknown device type #{device}"
      end
    end
    module_function :for_device
  end
end
