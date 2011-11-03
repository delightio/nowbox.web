Feature: Authentication
  Scenario: Getting a new token via HTTPS
    Given I have a user id and secret
    When I securely request a token
    Then I should receive a new token and time-to-live

  Scenario: Getting a new token via HTTP
    Given I have a user id and secret
    When I request a token
    Then I should receive an error

