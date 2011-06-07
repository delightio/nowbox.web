module Aji
  class Channel < ActiveRecord::Base
# ## Channel Schema
    # - id: Integer
    # - title: String
    # - videos_key: String (Redis key)
    # - channel_type: String
    # - contributors_key: String (Redis key)
    # - created_at: DateTime
    # - updated_at: DateTime
  end
end
