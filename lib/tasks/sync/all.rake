namespace :sync do
  desc 'Update only latest products on local machine'
  task latest: :environment do
    supplier = Supplier.from_env
    supplier.sync_latest supplier.each_url_for(:latest_sync)
  end

  desc 'Update all products on local machine'
  task all: :environment do
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
    Supplier.from_env.sync_orders_counts
  end

  desc "Create sync wide task"
  task wide: :environment do
    supplier = Supplier.from_env

    ActiveRecord::Base.transaction do
      task = WideSyncTask.create! supplier: supplier

      supplier.each_url_for(:wide_sync) do |url|
        SourceLink.create! url: url, wide_sync_task: task
      end
    end

    task.enqueue_job
  end
end
