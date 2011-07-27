Feature: Twitter account based Channels
  In order to enjoy videos shared by people
  As a Nowmov user
  I want to see videos shared on Twitter

  Scenario: Fetching or creating a new twitter channel
    Given I am logged in as a nowmov user
    When I ask for a channel containing @nowmov's videos
    Then I should get a channel for videos shared by @nowmov
    And the title should be "@nowmov's Tweeted Videos"

  Scenario: Viewing a twitter channel's videos
    Given the channel with id 5 is @nowmov's twitter channel
    And @nowmov has tweeted videos recently
    When I get the channels videos
    Then I should see a list of recently tweeted videos
