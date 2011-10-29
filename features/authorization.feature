Feature: Twitter Authorization
  In order to see videos my friends post
  As a social nitwit
  I want to authorize my twitter account

  Scenario: User authorizes for the first time
    Given this account has never been authorized before
    When the callback url is triggered with a user_id
    Then the status code should be 200
    And there should be no errors
