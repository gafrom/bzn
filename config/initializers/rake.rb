require 'rake'

Rails.application.load_tasks if Rake::Task.tasks.blank?
Rake::Task.include Extensions::MeasuringRakeTasks
