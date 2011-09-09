Feature: Twitter account based Channels
  In order to enjoy videos shared by people
  As a Nowmov user
  I want to see videos shared on Twitter

  Scenario: Fetching or creating a new twitter channel
    Given I am logged in as a nowbox user
    When I ask for a channel containing @nowbox's videos
    Then I should get a channel for videos shared by @nowbox
    And the title should be "@nowbox's Tweeted Videos"

  Scenario: Viewing a twitter channel's videos
    Given a Twitter channel associated with @nowbox's twitter account
    And @nowbox has tweeted videos recently
    When I get the channels videos
    Then I should see a list of recently tweeted videos
