lock '3.10.0'

set :application, 'bzn'
set :repo_url, 'git@github.com:gafrom/bzn.git'

set :rbenv_ruby, '2.4.2'
set :rbenv_map_bins, %w(rake gem bundle ruby rails eye)

set :ssh_options, forward_agent: true
set :bundle_jobs, 4
set :bundle_env_variables, nokogiri_use_system_libraries: 1

set :eye_roles, -> { :app }
set :eye_config, 'config/eye.rb'
set :deploy_to, -> { '~/bzn' }

# set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

append :linked_files, '.env.production'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'db/backups', 'storage'
