module Aji
  module Channels
    class AuthorsChannel < Channel
      has_and_belongs_to_many :authors
      def populate
        authors.each_with_index do |a, i|
          a.videos.members.each_with_index do |v, k|
            # Until I can write my own Redis-backed ZSet class or come up with
            # a suitable interface to Redis::Objects::SortedSet, this is a 
            # clever trick to get unique ranks for each video into a channel.
            videos[v] = "#{i + 1}#{k + 1}".to_i
          end
        end
      end
    end
  end
end
