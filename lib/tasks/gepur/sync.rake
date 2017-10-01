namespace :gepur do
  desc 'Update products on local machine'
  task sync: :environment do
    Gepur::Catalog.new.sync
  end
end
