# server time, currently set to UTC

every '26 * * * *' do
  rake 'sync:own supplier=wb'
end

every '7,37 0-21,23 * * 0-1,3-6' do
  # trick to set other env variables:
  # rake 'export:xlsx:wb', environment: 'production RAILS_LOG_LEVEL=1'
  rake 'sync:latest supplier=wb export:xlsx:wb'
end

every '2 22 * * 0-1,3-6' do
  rake 'sync:all supplier=wb export:xlsx:wb'
end

every '7,37 0-5 * * 2' do
  # trick to set other env variables:
  # rake 'export:xlsx:wb', environment: 'production RAILS_LOG_LEVEL=1'
  rake 'sync:latest supplier=wb export:xlsx:wb'
end

every :tuesday, at: '06:06' do
  rake 'sync:all supplier=wb export:xlsx:wb'
end

every :tuesday, at: '08:08' do
  rake 'sync:orders_counts supplier=wb export:xlsx:wb'
end

# 0 - Sunday
# 1 - Monday
# 2 - Tuesday
# 3 - Wednesday
# 4 - Thursday
# 5 - Friday
# 6 - Saturday
