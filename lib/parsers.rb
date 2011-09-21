module Aji::Parsers
  autoload :Tweet, "#{Aji.root}/lib/parsers/tweet"
  autoload :FBLink, "#{Aji.root}/lib/parsers/fb_link"

  def self.[] source
    parsers[source.to_sym]
  end

  def parsers
    { :twitter => Tweet, :facebook => FBLink }
  end

  module_function :parsers
end
