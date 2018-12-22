class Admin::ReportsController < ApplicationController
  before_action :set_dates, only: :create

  def create
    DailyReportJob.perform_later *@dates.map(&:to_s)

    human_dates = @dates.map { |date| I18n.l(date) }

    redirect_to admin_root_path, notice: "Началось создание отчёта с #{human_dates.join(' по ')}"
  end

  private

  def set_dates
    @dates = [params[:start_at], params[:end_at]].map { |date_str| Date.parse(date_str) }
  rescue ArgumentError
    redirect_to admin_root_path, alert: 'Неверный формат дат'
  end
end
