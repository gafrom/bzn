class Admin::ReportsController < ApplicationController
  before_action :set_dates

  def daily
    DailyReportJob.perform_later *@dates.map(&:to_s)

    human_dates = @dates.map { |date| I18n.l(date) }

    redirect_to admin_root_path, notice: "Set for processing report: #{human_dates}"
  end

  private

  def set_dates
    @dates = [params[:start_at], params[:end_at]].map { |date_str| Date.parse(date_str) }
  end
end
