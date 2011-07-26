Feature: Twitter account based Channels
  In order to enjoy videos shared by people
  As a Nowmov user
  I want to see videos shared on Twitter

  Scenario:
    Given I am logged in as a nowmov user
    When I ask for a channel containing @nowmov's videos
    Then I should get a channel for videos shared by @nowmov
