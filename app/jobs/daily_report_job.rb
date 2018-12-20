class DailyReportJob < ApplicationJob
  queue_as :default

  def perform(*args)
    dates = args.map { |date_str| Date.parse(date_str) }
    DailyReport.new(*dates.first(2)).store
  end
end
