module Aji
  # ## Share Schema
  # - id: Integer
  # - hash: String
  # - message: Text
  # - user_id: Integer (Foreign Key)
  # - video_id: Integer (Foreign Key)
  class Share
    belongs_to :user
    belongs_to :video
  end
end
