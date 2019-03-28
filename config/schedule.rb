# server time, currently set to UTC

every :thursday, at: '08:10' do
  rake 'sync:all supplier=wb'
end

# every :sunday, at: '08:08' do
#   rake 'sync:orders_counts supplier=wb export:xlsx:wb'
# end
