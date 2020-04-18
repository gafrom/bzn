ROOT_PATH = File.expand_path('../..', __FILE__)

Eye.config do
  logger "#{ROOT_PATH}/log/eye.log"
end

Eye.application 'bzn' do
  working_dir ROOT_PATH

  trigger :flapping, times: 10, within: 1.minute, retry_in: 10.minutes

  env 'RAILS_ENV' => 'production'

  process :puma do
    daemonize true
    pid_file 'tmp/pids/puma.pid'
    stdall "#{ROOT_PATH}/log/puma.log"

    start_command "bundle exec puma -C config/puma.rb"
    stop_signals [:QUIT, 5.seconds, :KILL]
    start_grace 20.seconds
    restart_grace 25.seconds

    check :cpu, every: 30.seconds, below: 70, times: 3
    check :memory, every: 1.minute, below: 300.megabytes, times: [3, 5]
  end

  process :sidekiq do
    daemonize true
    pid_file "tmp/pids/sidekiq.pid"
    stdall "#{ROOT_PATH}/log/sidekiq.log"

    start_command "bundle exec sidekiq -c 1 -q default"

    start_grace 30.seconds
    restart_grace 50.seconds
    stop_signals [:TSTP, 5.seconds, :TERM, 12.seconds]

    check :cpu, every: 20.seconds, below: 95, times: 9
    check :memory, every: 1.minute, below: 150.megabytes, times: 3
  end

  process :sidekiq_reports do
    daemonize true
    pid_file "tmp/pids/sidekiq_reports.pid"
    stdall "#{ROOT_PATH}/log/sidekiq.log"

    start_command "bundle exec sidekiq -c 1 -q reports"

    start_grace 30.seconds
    restart_grace 45.seconds
    stop_signals [:TSTP, 5.seconds, :TERM, 12.seconds]

    check :cpu, every: 20.seconds, below: 95, times: 9
    check :memory, every: 1.minute, below: 300.megabytes, times: 3
  end
end
