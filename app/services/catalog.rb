require 'open-uri'
require 'csv'

class Catalog
  include Catalogue::WithSupplier

  STALE_IN = 10.hours
  NUM_THREADS = 16
  LOG_FILE = Rails.root.join 'log', 'parsing.log'

  def initialize(supplier_host = nil)
    @supplier_host  = supplier_host

    @processed = Set.new
    @failures_count = 0
    @created_count  = 0
    @updated_count  = 0
    @skipped_count  = 0
    @hidden_count   = 0

    @pool = ThreadPool.new self.class::NUM_THREADS
    @logger = Logger.new self.class::LOG_FILE
    @colorizer = Colorizer.new

    # workaround to ActiveRecord bug _load_missing_constant_
    Supplier; SizeArray; Category;
    AngelaRicci::Categorizer; Fly::Categorizer; Gepur::Categorizer; Wisell::Categorizer
  end

  private

  def log_failure_for(url, error)
    msg = "Processing #{url}... Failed: #{error}\n"
    @failures_count += 1
    @logger.error msg
    puts msg
  end

  def log_success_for(url, action = :done)
    puts "Processing #{url}... #{action.to_s.capitalize}\n"
  end

  def headers
    {}
  end
end
