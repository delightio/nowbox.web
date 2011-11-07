module Aji
  module RouteHelper

    def base_url
      "http://#{Aji.conf['TLD']}"
    end

    def share_url(id)
      [base_url, "share", id.to_s].join("/")
    end

    def random_url
      [base_url , "random"].join("/")
    end

  end
end