Feature: Users API
  Scenario: Creating an empty user
    When a user is created with no parameters
    Then the status code should be 400
    And there should be an error
    And no user is created

  Scenario: Creating a user with no details
    Given a user's locale and region
    When a user is created with those parameters
    Then the status code should be 201
    And the user should be created
    And the user should have no name or email
    But the user should have favorites, queue, and history channels

  Scenario: Creating a user with details
    Given a user's name and email
    And a user's locale and region
    When a user is created with those parameters
    Then the status code should be 201
    And the user should be created
    And the user should have that name, email, and region
    And the user should have favorites, queue, and history channels

  Scenario: Getting user info when authenticated
    Given a valid token for a user
    When getting that user's information
    Then the status code should be 200
    And the user's information should be present

   Scenario: Getting user info when authenticated as another user
    Given a valid token for a user
    When getting another user's information
    Then the status code should be 401
    And there should be an error

  Scenario: Getting user info when not authenticated
    Given a valid user id
    When getting that user's information
    Then the status code should be 401
    And there should be an error

  Scenario: Updating user info when authenticated
    Given a valid token for a user
    When updating that user's info
    Then the status code should be 200
    And the user's information should be present

 Scenario: Updating user info when authenticated as another user
    Given a valid token for a user
    When updating another user's info
    Then the status code should be 401
    And there should be an error

  Scenario: Updating user info when not authenticated
    Given a valid user id
    When updating that user's info
    Then the status code should be 401
    And there should be an error

  Scenario: Updating user settings when authenticated
    Given a valid token for a user
    When updating that user's settings
    Then the status code should be 200
    And the new settings should be present

  Scenario: Updating user settings when authenticated as another user
    Given a valid token for a user
    When updating another user's settings
    Then the status code should be 401
    And there should be an error

  Scenario: Updating user settings when not authenticated
    Given a valid user id
    When updating that user's settings
    Then the status code should be 401
    And there should be an error

  Scenario: Testing valid user authentication
    Given a valid token for a user
    When testing that user's authentication
    Then the status code should be 200

  Scenario: Testing user authentication with no token
    Given a valid user id
    When testing that user's authentication
    Then the status code should be 401
    And there should be an error

  Scenario: Testing user authentication for a different user
    Given a valid token for a user
    When testing another user's authentication
    Then the status code should be 401
    And there should be an error

  Scenario: Start synchronization of a user's youtube account
    Given a user with an authorized youtube account
    And a valid token for the user
    When requesting a synchronization occur
    Then the status code should be 202
    And the synchronization should be enqueued

  Scenario: Start synchronization of user's youtube account when unauthorized
    Given a user with an authorized youtube account
    When requesting a synchronization occur
    Then the status code should be 401
    And there should be an error

  Scenario: Start synchronization of a user with no youtube account
    Given a valid token for a user
    When requesting a synchronization occur
    Then the status code should be 400
    And there should be an error

