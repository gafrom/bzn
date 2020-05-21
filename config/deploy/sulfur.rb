set :rbenv_ruby, '2.6.2'
server ENV['SULFUR_HOST_PROD'], user: 'amara', roles: %w{app db web}
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :rails_env, 'production'
set :whenever_roles, [:sulfur]
