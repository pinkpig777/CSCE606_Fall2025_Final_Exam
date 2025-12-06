class StatsController < ApplicationController
  before_action :authenticate_user!

  def show
    @stats_service = StatsService.new(current_user)
    @overview = @stats_service.calculate_overview
    @top_contributors = @stats_service.calculate_top_contributors
    @trend_data = @stats_service.calculate_trend_data
    @heatmap_years = @stats_service.heatmap_years
    @heatmap_year = selected_heatmap_year(@heatmap_years)
    @heatmap_data = @stats_service.calculate_heatmap_data(year: @heatmap_year)
  end

  private

  def selected_heatmap_year(available_years)
    year_param = params[:heatmap_year].to_i
    return year_param if available_years.include?(year_param)
    available_years.first || Date.current.year
  end
end
