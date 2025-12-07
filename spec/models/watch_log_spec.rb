require 'rails_helper'

RSpec.describe WatchLog, type: :model do
  it 'has a valid factory' do
    expect(build(:watch_log)).to be_valid
  end

  it 'validates presence of watched_on' do
    log = build(:watch_log, watched_on: nil)
    expect(log).not_to be_valid
    expect(log.errors[:watched_on]).to include("can't be blank")
  end

  it 'rejects a future watched_on date' do
    log = build(:watch_log, watched_on: Date.tomorrow)
    expect(log).not_to be_valid
    expect(log.errors[:watched_on]).to include("can't be in the future")
  end

  it "rejects logging before the movie's release date" do
    movie = create(:movie, release_date: Date.new(2025, 1, 1))
    log = build(:watch_log, movie: movie, watched_on: Date.new(2024, 12, 31))
    expect(log).not_to be_valid
    expect(log.errors[:watched_on]).to include("can't be before the movie's release date")
  end

  it 'assigns user_id from watch_history before validation' do
    hist = create(:watch_history)
    log = build(:watch_log, watch_history: hist)
    # ensure user_id is nil initially on the in-memory object
    log.user_id = nil
    log.valid?
    expect(log.user_id).to eq(hist.user_id)
  end
end
