module Aji
  module Info
    def for_device device
      case device
      when "ipad"
        {
          :current_version => "1.0.23",
          :minimum_version => "1.0.21",
          :link => { :rel => "latest",
                     :url => "http://tflig.ht/rwxYEk" }
        }
      else
        raise Aji::Error, "Unknown device type #{device}"
      end
    end
    module_function :for_device
  end
end
