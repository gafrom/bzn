module DailyReport
  module Factory
    def self.build(task)
      case task
      when DailyReportByHourTask    then ByHour
      when DailyReportByDayTask     then ByDay
      when DailyReportWideSyncsTask then ByWeek
      when EntireSyncTask           then FullOneOff
      else raise "Unknown task type: #{task.type} - cannot choose report class to build it."
      end.new(task)
    end
  end
end
