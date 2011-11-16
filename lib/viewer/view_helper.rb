module Aji
  module ViewHelper

    def nil_on_fail(alternative = "")
      yield
    rescue
      alternative
    end

  end
end