# server time, currently set to UTC

every :monday, at: '07:57' do
  rake 'sync:all supplier=wb'
end

# every :friday, at: '20:28' do
#   rake 'sync:orders_counts supplier=wb'
# end
