namespace :sync do
  desc 'Update only latest products on local machine'
  task latest: :environment do
    supplier = Supplier.from_env
    supplier.sync_latest supplier.each_url_for(:latest_sync)
  end

  desc 'Update narrow range products on local machine'
  task narrow: :environment do
    supplier = Supplier.from_env
    supplier.sync_daily supplier.each_url_for(:narrow_sync)
  end

  desc 'Update products on local machine with hourly facts'
  task own: :environment do
    supplier = Supplier.from_env
    supplier.sync_hourly supplier.each_url_for(:own_sync)
  end

  desc "Update all products' orders counts on local machine"
  task orders_counts: :environment do
    supplier = Supplier.from_env
    products = Product
      .joins('INNER JOIN daily_facts ON products.id = daily_facts.product_id')
      .where('products.supplier_id = ? '\
             'AND daily_facts.created_at >= ? '\
             'AND daily_facts.is_available = ?', supplier.id, 1.week.ago.to_date, true)
      .distinct

    supplier.sync_orders_counts(products)
  end

  desc "Create sync wide task"
  task wide: :environment do
    supplier = Supplier.from_env
    sync_task = nil

    ActiveRecord::Base.transaction do
      sync_task = WideSyncTask.create! supplier: supplier

      supplier.each_url_for(:wide_sync) do |url|
        SourceLink.create! url: url, sync_task: sync_task
      end
    end

    sync_task.enqueue_job
  end

  desc "Create and enqueue entire sync task"
  task entire: :environment do
    supplier = Supplier.from_env
    sync_task = nil

    ActiveRecord::Base.transaction do
      sync_task = EntireSyncTask.create! supplier: supplier

      supplier.each_url_for(:entire_sync) do |url|
        SourceLink.create! url: url, sync_task: sync_task
      end
    end

    sync_task.enqueue_job
  end
end
