# server time, currently set to UTC

every '7,37 0-9,11-23 * * 1-6' do
  # trick to set other env variables:
  # rake 'export:xlsx:wb', environment: 'production RAILS_LOG_LEVEL=1'
  rake 'sync:latest supplier=wb export:xlsx:wb'
end

every '1 10 * * 1-6' do
  rake 'sync:all supplier=wb export:xlsx:wb'
end

every :sunday, at: '08:08' do
  rake 'sync:orders_counts supplier=wb export:xlsx:wb'
end
