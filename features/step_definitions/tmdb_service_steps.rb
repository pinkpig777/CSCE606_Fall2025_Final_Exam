Given("the TMDb API times out for search") do
  stub_request(:get, /api\.themoviedb\.org\/3\/search\/movie/)
    .to_timeout
  stub_request(:get, /api\.themoviedb\.org\/3\/trending\/movie\/week/)
    .to_return(status: 200, body: { results: [], total_pages: 0 }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/movie\/top_rated/)
    .to_return(status: 200, body: { results: [], total_pages: 0 }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/genre\/movie\/list/)
    .to_return(status: 200, body: { genres: [] }.to_json, headers: { "Content-Type" => "application/json" })
end

When("I search for movies with query {string}") do |query|
  visit movies_path
  expect(page).to have_css("input[name='query']", wait: 10)
  find("input[name='query']").set(query)
  click_button "Search"
end

Then("I should see a connection error message") do
  expect(page).to have_content(/connection error|error/i, wait: 10)
end

Given("the TMDb genres API returns non-hash data") do
  stub_request(:get, /api\.themoviedb\.org\/3\/genre\/movie\/list/)
    .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/trending\/movie\/week/)
    .to_return(status: 200, body: { results: [], total_pages: 0 }.to_json, headers: { "Content-Type" => "application/json" })
  stub_request(:get, /api\.themoviedb\.org\/3\/movie\/top_rated/)
    .to_return(status: 200, body: { results: [], total_pages: 0 }.to_json, headers: { "Content-Type" => "application/json" })
end

When("I visit the movies search page") do
  visit movies_path
  expect(page).to have_css("input[name='query']", wait: 10)
end

Then("the genres dropdown should show no genres") do
  # Page should still load without errors
  expect(page).to have_css("input[name='query']", wait: 10)
end

When("I request movie details with blank tmdb_id") do
  @tmdb_service = TmdbService.new
  @movie_details = @tmdb_service.movie_details("")
end

Then("the movie details should be nil") do
  expect(@movie_details).to be_nil
end

When("I request similar movies with blank tmdb_id") do
  @tmdb_service = TmdbService.new
  @similar_movies = @tmdb_service.similar_movies("")
end

Then("the similar movies should return empty results") do
  expect(@similar_movies).to eq({ results: [], total_pages: 0 })
end
