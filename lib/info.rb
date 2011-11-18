module Aji
  module Info
    def for_device device
      case device
      when "ipad"
        {
          :current_version => "1.0.18",
          :minimum_version => "1.0.18",
          :link => { :rel => "latest",
                     :url => "http://tflig.ht/tb9sfs" }
        }
      else
        raise Aji::Error, "Unknown device type #{device}"
      end
    end
    module_function :for_device
  end
end
