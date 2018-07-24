every 30.minutes do
  rake 'sync:latest supplier=wb'
end

every 1.day, at: '10:01 am' do # server time, currently set to UTC
  rake 'sync:all supplier=wb'
end
