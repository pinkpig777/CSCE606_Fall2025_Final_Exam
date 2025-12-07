require 'rails_helper'

RSpec.describe Log, type: :model do
  let(:user) { create(:user) }
  let(:movie) { create(:movie, release_date: Date.new(2024, 1, 1)) }

  it "is valid when watched on or after release date" do
    log = build(:log, user: user, movie: movie, watched_on: Date.new(2024, 1, 1), rating: 7)
    expect(log).to be_valid

    later_log = build(:log, user: user, movie: movie, watched_on: Date.new(2024, 2, 1), rating: 7)
    expect(later_log).to be_valid
  end

  it "is invalid when watched before release date" do
    log = build(:log, user: user, movie: movie, watched_on: Date.new(2023, 12, 31), rating: 7)
    expect(log).not_to be_valid
    expect(log.errors[:watched_on]).to include("can't be before the movie's release date")
  end

  it "allows missing release date" do
    movie.update(release_date: nil)
    log = build(:log, user: user, movie: movie, watched_on: Date.new(2024, 1, 1), rating: 7)
    expect(log).to be_valid
  end
end
