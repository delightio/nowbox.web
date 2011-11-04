Feature: Authorization
  In order to see videos my friends post
  As a social nitwit
  I want to authorize my twitter account

  Scenario: User authorizes with twitter for the first time
    Given this twitter account has never been authorized before
    When the twitter callback url is triggered with a user_id
    Then the status code should be 200

   Scenario: User authorizes with youtube for the first time
    Given this youtube account has never been authorized before
    When the youtube callback url is triggered with a user_id
    Then the status code should be 200
    And there should be no errors
    And the account should be linked with the user's identity
    And a synchronization job should be enqueued
