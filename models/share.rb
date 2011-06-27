module Aji
  # ## Share Schema
  # - id: Integer
  # - message: Text
  # - user_id: Integer (Foreign Key)
  # - video_id: Integer (Foreign Key)
  class Share < ActiveRecord::Base
    belongs_to :user
    belongs_to :video

  end
end
