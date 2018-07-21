require 'rake'

Rails.application.load_tasks
Rake::Task.include Extensions::MeasuringRakeTasks
