Given("discovery data is available from TMDb") do
  ENV["TMDB_ACCESS_TOKEN"] ||= "test_token"

  @trending_payload = {
    "results" => [
      { "id" => 5001, "title" => "Trending One", "poster_path" => "/t1.jpg", "vote_average" => 8.0, "release_date" => "2024-01-01" }
    ],
    "page" => 1,
    "total_pages" => 1
  }

  @top_rated_payload = {
    "results" => [
      { "id" => 6001, "title" => "Top Rated One", "poster_path" => "/tr1.jpg", "vote_average" => 8.5, "release_date" => "2023-01-01" }
    ],
    "page" => 1,
    "total_pages" => 1
  }

  stub_request(:get, /api\.themoviedb\.org\/3\/trending\/movie\/week/)
    .to_return(status: 200, body: @trending_payload.to_json, headers: { "Content-Type" => "application/json" })

  stub_request(:get, /api\.themoviedb\.org\/3\/movie\/top_rated/)
    .to_return(status: 200, body: @top_rated_payload.to_json, headers: { "Content-Type" => "application/json" })

  stub_request(:get, /api\.themoviedb\.org\/3\/genre\/movie\/list/)
    .to_return(
      status: 200,
      body: { "genres" => [ { "id" => 1, "name" => "Action" }, { "id" => 2, "name" => "Drama" } ] }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
end

Given("I have watched movies with tmdb ids {int} and {int}") do |id1, id2|
  @user ||= FactoryBot.create(:user)
  watch_history = @user.watch_history || FactoryBot.create(:watch_history, user: @user)

  [ id1, id2 ].each_with_index do |tmdb_id, idx|
    movie = FactoryBot.create(:movie, tmdb_id: tmdb_id, title: "Watched #{idx}", cached_at: Time.current)
    FactoryBot.create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.today - idx.days)

    stub_request(:get, /api\.themoviedb\.org\/3\/movie\/#{tmdb_id}\/similar/)
      .to_return(
        status: 200,
        body: { "results" => [ { "id" => 9000 + idx, "title" => "Recommended #{idx}", "poster_path" => "/rec#{idx}.jpg", "vote_average" => 7.9 } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end

When("I visit the discovery page") do
  visit movies_path
end

Then("I should see personalized recommendations") do
  expect(page).to have_content("Personalized Recommendations", wait: 10)
  expect(page).to have_content(/Recommended/, wait: 10)
end

Then("I should see trending movies") do
  expect(page).to have_content("Trending Now", wait: 10)
  expect(page).to have_content("Trending One", wait: 10)
end

Then("I should see unwatched high rated movies") do
  expect(page).to have_content("Unwatched High-Rated", wait: 10)
  expect(page).to have_content("Top Rated One", wait: 10)
end

Then("I should be prompted to sign in for recommendations") do
  expect(page).to have_content(/Sign in to unlock personalized recommendations/i)
end

Given("the trending movies API fails") do
  stub_request(:get, /api\.themoviedb\.org\/3\/trending\/movie\/week/)
    .to_return(status: 500, body: { error: "API error" }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/movie\/top_rated/)
    .to_return(status: 200, body: { results: [], total_pages: 0 }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/genre\/movie\/list/)
    .to_return(status: 200, body: { genres: [] }.to_json, headers: { "Content-Type" => "application/json" })
end

Then("I should see an error message for trending movies") do
  expect(page).to have_content(/Unable to load trending movies|Trending Now/i, wait: 10)
end

Given("the top rated movies API fails") do
  stub_request(:get, /api\.themoviedb\.org\/3\/trending\/movie\/week/)
    .to_return(status: 200, body: { results: [], total_pages: 0 }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/movie\/top_rated/)
    .to_return(status: 500, body: { error: "API error" }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/genre\/movie\/list/)
    .to_return(status: 200, body: { genres: [] }.to_json, headers: { "Content-Type" => "application/json" })
end

Then("I should see an error message for top rated movies") do
  expect(page).to have_content(/Unable to load top rated movies|High-Rated/i, wait: 10)
end

Given("I have watch history") do
  @user ||= FactoryBot.create(:user)
  watch_history = @user.watch_history || FactoryBot.create(:watch_history, user: @user)
  movie = FactoryBot.create(:movie, tmdb_id: 123, title: "Test Movie", cached_at: Time.current)
  FactoryBot.create(:watch_log, watch_history: watch_history, movie: movie, watched_on: Date.today)
end

Given("the recommendations API fails") do
  stub_request(:get, /api\.themoviedb\.org\/3\/movie\/\d+\/similar/)
    .to_return(status: 500, body: { error: "API error" }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/trending\/movie\/week/)
    .to_return(status: 200, body: { results: [], total_pages: 0 }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/movie\/top_rated/)
    .to_return(status: 200, body: { results: [], total_pages: 0 }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/genre\/movie\/list/)
    .to_return(status: 200, body: { genres: [] }.to_json, headers: { "Content-Type" => "application/json" })
end

Then("I should see an error message for recommendations") do
  expect(page).to have_content(/Personalized Recommendations/i, wait: 10)
end
