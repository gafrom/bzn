every 15.minutes do
  rake 'sync:latest supplier=wb'
end

every 1.day, at: '4:30 am' do
  rake 'sync:all supplier=wb'
end
