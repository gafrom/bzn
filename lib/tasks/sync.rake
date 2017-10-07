desc 'Update products on local machine'
task :sync, [:supplier] => :environment do |t, params|
  supplier = params[:supplier].to_s.camelcase.constantize

  supplier::Catalog.new.sync
end
