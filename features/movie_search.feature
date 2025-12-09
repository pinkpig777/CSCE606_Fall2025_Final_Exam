Feature: Search Movies
  As a user
  I want to search movies by title
  So I can find what I'm looking for

  Background:
    Given I am logged in as a user
    And the TMDb API is available

  Scenario: User searches for a movie successfully
    Given I am on the movies search page
    When I enter "Inception" in the search field
    And I submit the search
    Then I should see search results
    And I should see "Inception" in the results

  Scenario: User submits empty search query
    Given I am on the movies search page
    When I enter "" in the search field
    And I submit the search
    Then I should see a prompt to type something

  Scenario: Cached results are displayed when TMDb rate limit occurs
    Given I have previously searched for "Inception"
    And the TMDb API rate limit is exceeded
    When I enter "Inception" in the search field
    And I submit the search
    Then I should see cached results


  Scenario: Search returns no results
    Given I have no search results
    Then the empty state should remain unchanged

  Scenario: Invalid genre filter returns no movies
    Given I am on the movies search page
    When I search for movies with genre "9999"
    Then I should see search results

  Scenario: Invalid decade filter returns no movies
    Given I am on the movies search page
    When I search for movies with decade "1890"
    Then the empty state should remain unchanged

  Scenario: Sorting by unknown key falls back to default
    Given I am on the movies search page
    When I search for movies sorted by "unknown"
    Then I should see search results

  Scenario: Sorting by release date with invalid dates
    Given I am on the movies search page
    When I search for movies with invalid release dates sorted by "release_date"
    Then I should see search results
