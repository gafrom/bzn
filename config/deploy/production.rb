server ENV['BZN_HOST_PROD'], user: 'bobby', roles: %w{app db web crawler}
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :rails_env, 'production'
set :whenever_roles, [:crawler]
