# server time, currently set to UTC

every '7,37 0-9,11-23 * * *' do
  rake 'sync:latest supplier=wb export:xlsx:wb'
end

every 1.day, at: '10:01 am' do
  rake 'sync:all supplier=wb export:xlsx:wb'
end
