class StatsService
  def initialize(user)
    @user = user
  end

  def calculate_overview
    logs = user_watch_logs.includes(:movie)
    legacy_logs = user_logs
    {
      total_movies: logs.select(:movie_id).distinct.count,
      total_hours: calculate_total_hours(logs),
      total_reviews: @user.reviews.count,
      total_rewatches: legacy_logs.where(rewatch: true).count,
      genre_breakdown: calculate_genre_breakdown(logs)
    }
  rescue StandardError => e
    Rails.logger.error("StatsService#calculate_overview error: #{e.message}")
    {
      total_movies: 0,
      total_hours: 0,
      total_reviews: 0,
      total_rewatches: 0,
      genre_breakdown: {}
    }
  end

  def calculate_top_contributors
    logs = user_watch_logs.includes(movie: [ :genres, movie_people: :person ])
    {
      top_genres: calculate_top_genres(logs),
      top_directors: calculate_top_directors(logs),
      top_actors: calculate_top_actors(logs)
    }
  end

  def calculate_trend_data
    logs = user_watch_logs.where.not(watched_on: nil).order(watched_on: :asc)
    {
      activity_trend: calculate_activity_trend(logs),
      rating_trend: calculate_rating_trend_from_watch_logs(logs)
    }
  end

  def calculate_heatmap_data(year: Date.current.year)
    logs = user_watch_logs.where.not(watched_on: nil)
    start_date = Date.new(year, 1, 1)
    end_date = [ Date.new(year, 12, 31), Date.today ].min
    logs = logs.where(watched_on: start_date..end_date)
    heatmap_hash = {}

    logs.each do |log|
      date = log.watched_on.to_date
      key = date.to_s
      heatmap_hash[key] ||= 0
      heatmap_hash[key] += 1
    end

    # 生成过去一年的日期范围（从今天往前推365天）
    # 填充所有日期（包括没有数据的日期）
    (start_date..end_date).each do |date|
      key = date.to_s
      heatmap_hash[key] ||= 0
    end

    heatmap_hash
  end

  def heatmap_years
    years = user_watch_logs.where.not(watched_on: nil)
      .pluck(Arel.sql("EXTRACT(YEAR FROM watched_on)::int")).uniq
    years.present? ? years.sort.reverse : [ Date.current.year ]
  rescue StandardError
    [ Date.current.year ]
  end

  private

  def user_watch_logs
    # Prefer the user's watch history; fall back to user_id for resilience
    return WatchLog.none unless @user
    @user.watch_history&.watch_logs || WatchLog.where(user_id: @user.id)
  end

  def user_logs
    return Log.none unless @user
    @user.logs
  end

  def calculate_total_hours(logs)
    # Runtime is stored in minutes, return in minutes (will be converted to hours in view)
    # Use pluck to avoid loading all movie objects
    movie_ids = logs.pluck(:movie_id)
    Movie.where(id: movie_ids).sum(:runtime) || 0
  end

  def calculate_genre_breakdown(logs)
    genre_counts = Hash.new(0)

    logs.each do |log|
      log.movie.genres.each do |genre|
        genre_counts[genre.name] += 1
      end
    end

    genre_counts.sort_by { |_name, count| -count }.to_h
  end

  def calculate_top_genres(logs, limit: 10)
    genre_counts = Hash.new(0)

    logs.each do |log|
      log.movie.genres.each do |genre|
        genre_counts[genre.name] += 1
      end
    end

    genre_counts.sort_by { |_name, count| -count }.first(limit).map do |name, count|
      { name: name, count: count }
    end
  end

  def calculate_top_directors(logs, limit: 10)
    director_counts = Hash.new { |h, k| h[k] = { count: 0, profile_path: nil } }

    # Get all movie IDs from logs
    movie_ids = logs.map(&:movie_id).uniq

    # Query all directors at once
    MoviePerson.where(movie_id: movie_ids, role: "director").includes(:person).each do |mp|
      entry = director_counts[mp.person.name]
      entry[:count] += 1
      entry[:profile_path] ||= mp.person&.profile_path
    end

    director_counts.sort_by { |_name, data| -data[:count] }.first(limit).map do |name, data|
      { name: name, count: data[:count], profile_path: data[:profile_path] }
    end
  end

  def calculate_top_actors(logs, limit: 10)
    actor_counts = Hash.new { |h, k| h[k] = { count: 0, profile_path: nil } }

    # Get all movie IDs from logs
    movie_ids = logs.map(&:movie_id).uniq

    # Query all actors at once
    MoviePerson.where(movie_id: movie_ids, role: "cast").includes(:person).each do |mp|
      entry = actor_counts[mp.person.name]
      entry[:count] += 1
      entry[:profile_path] ||= mp.person&.profile_path
    end

    actor_counts.sort_by { |_name, data| -data[:count] }.first(limit).map do |name, data|
      { name: name, count: data[:count], profile_path: data[:profile_path] }
    end
  end

  def calculate_activity_trend(logs)
    start_window = 365.days.ago.to_date.beginning_of_month
    end_window = Date.current.end_of_month

    scoped = logs.where("watched_on >= ?", start_window)

    monthly_counts = Hash.new(0)
    scoped.each do |log|
      next unless log.watched_on
      month_key = log.watched_on.strftime("%Y-%m")
      monthly_counts[month_key] += 1
    end

    # Fill missing months with zero so the chart shows continuity
    results = []
    current_month = start_window
    while current_month <= end_window
      key = current_month.strftime("%Y-%m")
      results << { month: key, count: monthly_counts[key] || 0 }
      current_month = current_month.next_month
    end

    results
  end

  def calculate_rating_trend_from_watch_logs(logs)
    monthly_data = {}
    return [] if logs.blank?

    # Load matching Log entries (where ratings live) keyed by movie/watched_on
    movie_ids = logs.map(&:movie_id).uniq
    dates = logs.map(&:watched_on).compact.uniq
    ratings = Log.where(user_id: @user.id, movie_id: movie_ids, watched_on: dates).where.not(rating: nil)
    ratings_index = ratings.each_with_object({}) do |log, h|
      h[[log.movie_id, log.watched_on]] = log.rating
    end

    logs.each do |watch_log|
      next unless watch_log.watched_on
      rating = ratings_index[[watch_log.movie_id, watch_log.watched_on]]
      next unless rating

      month_key = watch_log.watched_on.strftime("%Y-%m")
      monthly_data[month_key] ||= { total: 0, count: 0 }
      monthly_data[month_key][:total] += rating
      monthly_data[month_key][:count] += 1
    end

    monthly_data.sort_by { |month, _data| month }.map do |month, data|
      avg_rating = data[:count] > 0 ? (data[:total].to_f / data[:count]).round(2) : 0
      { month: month, average_rating: avg_rating }
    end
  end
end
