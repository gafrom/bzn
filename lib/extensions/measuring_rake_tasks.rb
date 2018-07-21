module Extensions
  module MeasuringRakeTasks
    def self.included(base)
      base.class_eval do
        alias_method :execute_without_measure, :execute
        alias_method :execute, :execute_with_measure
      end
    end

    def execute_with_measure(*args)
      started_at = Time.zone.now
      Rails.logger.info "Task [\e[34;1m#{name}\e[0m] \e[32mstarted\e[0m " \
                        "at \e[1m#{started_at}\e[0m."

      execute_without_measure(*args)

      duration = (Time.zone.now - started_at).duration
      Rails.logger.info "Task [\e[34;1m#{name}\e[0m] is \e[32mcompleted\e[0m " \
                        "in \e[1m#{duration}\e[0m."
    end
  end
end
