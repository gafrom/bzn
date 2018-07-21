every 15.minutes do
  rake 'sync:latest supplier=wb'
end

every 1.day, at: '10:00 am' do # server time, currently set to UTC
  rake 'sync:all supplier=wb'
end
