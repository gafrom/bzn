namespace :sync do
  desc 'Scrape over all links and store them into DB'
  task links: :environment do
    supplier_module = ENV['supplier'].to_s.camelcase.constantize
    supplier_module::Catalog.new(ENV['host'])
                            .sync_links_from :complete_urls_set, till_first_existing: false

    puts "Scraped all links and stored them to DB ✅"
  end

  desc 'Scrape over recently added links and store them into DB'
  task latest_links: :environment do
    supplier_module = ENV['supplier'].to_s.camelcase.constantize
    supplier_module::Catalog.new(ENV['host'])
                            .sync_links_from :latest_products_url, till_first_existing: true

    puts "Scraped latest links, stored them to DB and went home ✅"
  end

  desc 'Update only latest products on local machine'
  task latest: :environment do
    supplier_module = ENV['supplier'].to_s.camelcase.constantize

    supplier_module::Catalog.new(ENV['host']).sync only_new: true
  end

  desc 'Update all products on local machine'
  task all: :environment do
    supplier_module = ENV['supplier'].to_s.camelcase.constantize

    supplier_module::Catalog.new(ENV['host']).sync only_new: false
  end
end