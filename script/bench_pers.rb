require './aji'
require 'benchmark'
include Aji

user = User.find 1
channel = Channel.find 218

Benchmark.bm(7) do |b|
  b.report("page01") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 1) } }
  b.report("page02") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 2) } }
  b.report("page03") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 3) } }
  b.report("page04") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 4) } }
  b.report("page05") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 5) } }
  b.report("page06") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 6) } }
  b.report("page07") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 7) } }
  b.report("page08") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 8) } }
  b.report("page09") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 9) } }
  b.report("page10") {10.times {  channel.personalized_content_videos(user: user, limit: 5, page: 10) } }
end
