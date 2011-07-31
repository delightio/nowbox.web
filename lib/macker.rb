module Aji
  module Macker
    autoload :Youtube, "#{Aji.root}/lib/macker/youtube"
    attr_reader :sources

    # TODO: Is there a more interesting way than Case to solve this?
    def Macker.fetch source, source_id
      fail ArgumentError.new "No interface for #{source}" unless
        sources.has_key? source

      sources[source].fetch source_id
    end

    def Macker.sources
      @sources ||= { :youtube => Youtube }
    end
  end
end
