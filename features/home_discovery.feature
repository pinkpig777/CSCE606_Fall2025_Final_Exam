Feature: Discovery Page
  As a user
  I want to see trending, top-rated, and recommended movies
  So I can discover new content

  Background:
    Given I am logged in as a user
    And the TMDb API is available

  Scenario: Trending movies API returns error
    Given the trending movies API fails
    When I visit the discovery page
    Then I should see an error message for trending movies

  Scenario: Top rated movies API returns error
    Given the top rated movies API fails
    When I visit the discovery page
    Then I should see an error message for top rated movies

  Scenario: Recommendations API returns error
    Given I have watch history
    And the recommendations API fails
    When I visit the discovery page
    Then I should see an error message for recommendations
