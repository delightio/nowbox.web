module Aji
  module Macker
    # A module to tag exceptions with so library users can catch either standard
    # errors or Macker::Error errors.
    Error = Module.new
    autoload :Youtube, "#{Aji.root}/lib/macker/youtube"
    autoload :Search, "#{Aji.root}/lib/macker/search"

    # TODO: Is there a more interesting way than Case to solve this?
    def Macker.fetch source, source_id
      fail ArgumentError.new "No interface for #{source}" unless
        sources.has_key? source

      sources[source].fetch source_id
    end

    def Macker.sources
      @sources ||= { :youtube => Youtube }
    end

    class FetchError < RuntimeError
      extend Error
      attr_accessor :source, :source_id
      def intialize message, source, source_id
        @source = source
        @source_id = source_id
      end
    end
  end
end
