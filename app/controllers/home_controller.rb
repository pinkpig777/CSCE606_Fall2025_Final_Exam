class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index
    if user_signed_in?
      following_ids = current_user.followed_user_ids

      # Activity Feed: Reviews and Logs from followed users
      recent_window = 14.days.ago
      @activities = []
      @activities += Review.where(user_id: following_ids).where("created_at >= ?", recent_window).includes(:user, :movie)
      @activities += WatchLog.where(user_id: following_ids).where("created_at >= ?", recent_window).includes(:watch_history, :movie)
      @activities += Vote.where(user_id: following_ids).where("created_at >= ?", recent_window).includes(:user, review: :movie)
      @activities += Follow.where(follower_id: following_ids).where("created_at >= ?", recent_window).includes(:follower, :followed)

      @activities = @activities.sort_by(&:created_at).reverse

      # Simple pagination
      @page = params[:page].to_i
      @page = 1 if @page < 1
      per_page = 10
      @total_pages = (@activities.size / per_page.to_f).ceil
      @activities = @activities.slice((@page - 1) * per_page, per_page) || []
    end

    # Trending movies for guest view or sidebar
    @trending_movies = Movie.order(created_at: :desc).limit(4)
    @trending_count = @trending_movies.size
    @high_rated_unwatched_count = 0

    begin
      tmdb = TmdbService.new

      trending_data = tmdb.trending_movies || {}
      @trending_count = (trending_data["results"] || trending_data[:results] || []).size if trending_data.present?

      watched_tmdb_ids = []
      if user_signed_in?
        watch_history = current_user.watch_history
        if watch_history&.watch_logs&.exists?
          watched_tmdb_ids = watch_history.watch_logs.includes(:movie).map { |wl| wl.movie&.tmdb_id }.compact.uniq
        end
      end

      top_rated_data = tmdb.top_rated_movies || {}
      high_rated = top_rated_data["results"] || top_rated_data[:results] || []
      filtered = high_rated.select { |movie| (movie["vote_average"] || 0) >= 7.5 }
      filtered = filtered.reject { |movie| watched_tmdb_ids.include?(movie["id"]) }
      @high_rated_unwatched_count = filtered.first(12).size
    rescue StandardError => e
      Rails.logger.warn("Home#index stats fallback: #{e.message}") if defined?(Rails)
    end
  end
end
