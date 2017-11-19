server '151.248.118.98', user: 'bobby', roles: %w{app db web}
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
# set :branch, 'develop'
set :rails_env, 'production'
