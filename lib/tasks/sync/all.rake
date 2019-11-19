namespace :sync do
  desc 'Scrape over all links and store them into DB'
  task links: :environment do
    supplier_module = ENV['supplier'].to_s.camelcase.constantize
    supplier_module::Catalog.new(ENV['host'])
                            .sync_links_from :complete_urls_set, till_first_existing: false

    Rails.logger.info "Scraped all links and stored them to DB ✅"
  end

  desc 'Scrape over recently added links and store them into DB'
  task latest_links: :environment do
    supplier_module = ENV['supplier'].to_s.camelcase.constantize
    supplier_module::Catalog.new(ENV['host'])
                            .sync_links_from :latest_products_url, till_first_existing: true

    Rails.logger.info "Scraped latest links, stored them to DB and went home ✅"
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

  desc 'Update own products on local machine'
  task own: :environment do
    supplier_module = ENV['supplier'].to_s.camelcase.constantize

    supplier_module::Catalog.new(ENV['host']).sync_own
  end

  desc "Update all products's orders counts on local machine"
  task orders_counts: :environment do
    supplier_module = ENV['supplier'].to_s.camelcase.constantize

    supplier_module::Catalog.new(ENV['host']).sync_orders_counts
  end
end
