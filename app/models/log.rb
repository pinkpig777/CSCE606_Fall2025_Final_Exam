class Log < ApplicationRecord
  belongs_to :user
  belongs_to :movie

  validates :rating, presence: true, inclusion: { in: 1..10 }
  validates :watched_on, presence: true
  validate :watched_on_not_before_release

  private

  def watched_on_not_before_release
    return unless watched_on.present? && movie&.release_date.present?
    release_date = movie.release_date.is_a?(Date) ? movie.release_date : movie.release_date.to_date rescue nil
    return unless release_date
    errors.add(:watched_on, "can't be before the movie's release date") if watched_on < release_date
  end
end
