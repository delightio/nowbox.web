module Aji
  class Language

    def initialize id_tag
      @id_tag = id_tag
    end

    def default_iso_code; "en"; end
    def iso_code
      return default_iso_code if @id_tag.to_s.empty?
      lang = @id_tag.split("_").first
      lang = lang.split("-").first if lang.length > 2
      lang = default_iso_code if lang.length > 2
      lang
    end

  end
end