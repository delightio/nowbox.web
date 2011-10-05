module Aji
  class Language

    def initialize locale
      @locale = locale
    end

    def default_iso_code; "en"; end
    def iso_code
      return default_iso_code if @locale.to_s.empty?
      lang = @locale.split("_").first
      lang = lang.split("-").first if lang.length > 2
      lang = default_iso_code if lang.length > 2
      lang
    end

  end
end