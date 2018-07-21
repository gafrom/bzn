module Extensions
  module DurationToNumeric
    def duration
      secs  = round(3)
      mins  = secs.to_int / 60
      hours = mins / 60
      days  = hours / 24

      case
      when days > 0 then "#{days} days and #{hours % 24} hours"
      when hours > 0 then "#{hours} hours and #{mins % 60} minutes"
      when mins > 0 then  "#{mins} minutes and #{secs % 60} seconds"
      when secs >= 0 then "#{secs} seconds"
      end
    end
  end
end
