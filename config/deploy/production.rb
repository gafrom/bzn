server ENV['BZN_HOST_PROD'], user: 'bobby', roles: %w{app db web}
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :rails_env, 'production'
set :whenever_roles, [:bzn]
