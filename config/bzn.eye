ROOT_PATH = File.expand_path('../..', __FILE__)

Eye.config do
  logger "#{ROOT_PATH}/log/eye.log"
end

Eye.application 'bzn' do
  working_dir ROOT_PATH

  trigger :flapping, times: 10, within: 1.minute, retry_in: 10.minutes
  check :cpu, every: 10.seconds, below: 100, times: 3

  env 'RAILS_ENV' => 'production'

  process :puma do
    daemonize true
    pid_file 'tmp/pids/puma.pid'
    stdall "#{ROOT_PATH}/log/puma.log"

    start_command "bundle exec puma -C config/puma.rb"
    stop_signals [:QUIT, 5.seconds, :KILL]
    restart_command 'kill -QUIT {PID}'

    restart_grace 10.seconds

    check :cpu, every: 30, below: 70, times: 3
    check :memory, every: 1.minute, below: 400.megabytes, times: [3, 5]
  end
end
