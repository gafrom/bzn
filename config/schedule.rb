# server time, currently set to UTC

every :friday, at: '12:01' do
  rake 'sync:all supplier=wb'
end

# every :sunday, at: '08:08' do
#   rake 'sync:orders_counts supplier=wb export:xlsx:wb'
# end
