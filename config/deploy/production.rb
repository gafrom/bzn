server '5.63.152.125', user: 'amara', roles: %w{app db web}
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
# set :branch, 'develop'
set :rails_env, 'production'
