module Aji::Parsers
  autoload :Tweet, "#{Aji.root}/lib/parsers/tweet"

  def self.[] source
    parsers[source.to_sym]
  end

  def parsers
    { :twitter => Tweet }
  end
  module_function :parsers
end
