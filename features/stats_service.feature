Feature: Stats service resilience
  As the system
  I want stats to handle errors gracefully

  Background:
    Given I am logged in as a user

  Scenario: Stats overview handles errors
    When I trigger stats overview with a failing movie query
    Then stats overview should not raise an error

  Scenario: Most watched movies handles errors
    When I trigger most watched movies with a failing query
    Then most watched movies should not raise an error

  Scenario: Update runtime handles tmdb errors
    Given a movie exists with tmdb id "7300" and no runtime
    When I trigger runtime update with failing tmdb
    Then runtime update should not raise an error

  Scenario: Most watched movies with rewatches from watch history
    Given I have watched the same movie 3 times
    When I calculate most watched movies
    Then the movie should show 3 watches and 2 rewatches

  Scenario: Most watched movies with legacy rewatch flags
    Given I have logged movies with legacy rewatch flags
    When I calculate most watched movies
    Then the rewatch counts should include legacy flags

  Scenario: Most watched movies returns empty on error
    When I calculate most watched movies with invalid data
    Then most watched movies should return empty array

  Scenario: Calculate trend data for current year
    Given I have logged movies in different months of current year
    When I calculate trend data for current year
    Then I should see activity trend by month
    And I should see rating trend by month

  Scenario: Calculate trend data with no ratings
    Given I have logged movies without ratings in current year
    When I calculate trend data for current year
    Then rating trend should show zero averages

  Scenario: Calculate heatmap data for current year
    Given I have logged movies on specific dates this year
    When I calculate heatmap data for current year
    Then I should see counts for logged dates
    And I should see zeros for dates without logs

  Scenario: Calculate heatmap data fills all dates in year
    Given I have logged one movie this year
    When I calculate heatmap data for current year
    Then all dates in year should be present in heatmap

  Scenario: Heatmap years returns last 5 years with data
    Given I have logged movies in years 2023 and 2024
    When I get heatmap years
    Then I should see years with watch log data

  Scenario: Heatmap years handles no data gracefully
    Given I have no watch logs with dates
    When I get heatmap years
    Then I should see current year as default

  Scenario: Trend years returns last 5 years
    When I get trend years
    Then I should see last five years

  Scenario: Calculate genre breakdown with multiple genres per movie
    Given I have logged movies with multiple genres each
    When I calculate stats overview
    Then genre breakdown should count all genre occurrences

  Scenario: Calculate decade breakdown with various release dates
    Given I have logged movies from different decades
    When I calculate stats overview
    Then decade breakdown should group by decade

  Scenario: Calculate decade breakdown handles invalid dates gracefully
    Given I have logged movies with invalid release dates
    When I calculate stats overview
    Then decade breakdown should skip invalid dates

  Scenario: Calculate top contributors with actors and directors
    Given I have logged movies with cast and crew
    When I calculate top contributors
    Then I should see top actors with profile paths
    And I should see top directors with profile paths
    And I should see top genres

  Scenario: Resolved runtime uses movie runtime when available
    Given I have a movie with runtime 120 minutes
    When I calculate total hours
    Then runtime should come from movie record

  Scenario: Resolved runtime fetches from TMDB when missing
    Given I have a movie without runtime and valid tmdb id
    When I calculate total hours
    Then runtime should be fetched from TMDB
    And movie runtime should be updated

  Scenario: Resolved runtime caches TMDB results
    Given I have a movie without runtime
    When I calculate total hours twice
    Then TMDB should only be called once

  Scenario: Resolved runtime handles missing TMDB data
    Given I have a movie with no runtime and TMDB returns nothing
    When I calculate total hours
    Then runtime should be zero
    And cache should mark as missing

  Scenario: Calculate rewatch count from watch logs
    Given I have watched 2 movies multiple times each
    When I calculate stats overview
    Then rewatch count should reflect multiple watches

  Scenario: Calculate rewatch count includes legacy rewatches
    Given I have legacy logs marked as rewatches
    When I calculate stats overview
    Then rewatch count should include legacy flags

  Scenario: Activity trend includes all months in year
    Given I have logged movies in January and June only
    When I calculate trend data for current year
    Then all months should be present in activity trend
    And months without logs should show zero

  Scenario: Rating trend calculates monthly averages
    Given I have logged movies with ratings in different months
    When I calculate trend data for current year
    Then rating trend should show correct monthly averages
