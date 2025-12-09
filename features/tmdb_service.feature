Feature: TMDb Service Error Handling
  As the system
  I want TMDb service to handle various error scenarios gracefully

  Scenario: Search movies handles connection timeout
    Given I am logged in as a user
    And the TMDb API times out for search
    When I search for movies with query "Inception"
    Then I should see a connection error message

  Scenario: Genres API handles non-hash response
    Given I am logged in as a user
    And the TMDb genres API returns non-hash data
    When I visit the movies search page
    Then the genres dropdown should show no genres

  Scenario: Movie details handles blank tmdb_id
    Given I am logged in as a user
    When I request movie details with blank tmdb_id
    Then the movie details should be nil

  Scenario: Similar movies handles blank tmdb_id
    Given I am logged in as a user
    When I request similar movies with blank tmdb_id
    Then the similar movies should return empty results
