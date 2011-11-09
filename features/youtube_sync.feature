Feature: Youtube Synchronization
  Scenario: Favoriting a video
    Given a user authorized with youtube
    When favoriting a video that is not currently favorited
    Then that video should be a youtube favorite

  Scenario: Unfavoriting a video
    Given a user authorized with youtube
    When unfavoriting a currently favorited video
    Then that video should not be a youtube favorite

  Scenario: Queueing a video to watch later
    Given a user authorized with youtube
    When enqueueing a video that is not currently in watch later
    Then that video should be in the watch later playlist on youtube

  Scenario: Dequeueing a watched video
    Given a user authorized with youtube
    When dequeueing a video that is currently in watch later
    Then that video should not be in the watch later playlist on youtube

  Scenario: Subscribing to a channel
    Given a user authorized with youtube
    When subscribing to a channel
    Then that channel should be subscribed on youtube

  Scenario: Unsubscribing to a channel
    Given a user authorized with youtube
    When unsubscribing from a channel
    Then that channel should not be subscribed on youtube

  Scenario: Synchronizing channels, favorites, and watch later from youtube
    Given a user authorized with youtube
    When a synchronization occurs
    #Then all channels from youtube should be in the user's subscribed channels
    Then all videos favorited on youtube should be in the user's favorites
    And all videos in the watch later playlist should be in the user's favorites
    And the next synchronization should be scheduled
