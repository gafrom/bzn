# server time, currently set to UTC

set :roles, [:crawler]

every '26 * * * *' do
  rake 'sync:own supplier=wb'
end

every '7,37 * * * *' do
  # trick to set other env variables:
  # rake 'export:xlsx:wb', environment: 'production RAILS_LOG_LEVEL=1'
  rake 'sync:latest supplier=wb export:xlsx:wb'
end

every :tuesday, at: '08:08' do
  rake 'sync:orders_counts supplier=wb export:xlsx:wb'
end

every :day, at: '23:43' do
  rake 'sync:wide supplier=wb'
end

# 0 - Sunday
# 1 - Monday
# 2 - Tuesday
# 3 - Wednesday
# 4 - Thursday
# 5 - Friday
# 6 - Saturday
