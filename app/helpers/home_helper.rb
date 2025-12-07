module HomeHelper
  def watch_label(activity)
    return "Watched" unless activity.is_a?(WatchLog) || activity.is_a?(Log)
    return "Rewatched" if rewatch_activity?(activity)
    "Watched"
  end

  private

  def rewatch_activity?(activity)
    movie_id = activity.movie_id
    user_id = activity.respond_to?(:user_id) ? activity.user_id : nil
    user_id ||= activity.respond_to?(:watch_history) ? activity.watch_history&.user_id : nil
    return false unless user_id && movie_id

    watched_on = activity.respond_to?(:watched_on) ? activity.watched_on : activity.created_at
    prior_count = WatchLog.where(user_id: user_id, movie_id: movie_id)
                          .where("watched_on < ?", watched_on)
                          .count
    prior_count.positive?
  rescue StandardError
    false
  end
end
