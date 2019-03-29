# server time, currently set to UTC

# every :friday, at: '12:01' do
#   rake 'sync:all supplier=wb'
# end

every :friday, at: '20:28' do
  rake 'sync:orders_counts supplier=wb'
end
