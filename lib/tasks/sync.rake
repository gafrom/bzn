desc 'Update products on local machine'
task sync: :environment do
  supplier_module = ENV['supplier'].to_s.camelcase.constantize

  supplier_module::Catalog.new(ENV['host']).sync
end
