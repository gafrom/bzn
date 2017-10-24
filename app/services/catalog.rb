require 'open-uri'
require 'csv'

class Catalog
  STALE_IN = 10.hours
  THREADS_NUM = 16
  LOG_FILE = Rails.root.join 'log', 'parsing.log'

  def initialize(supplier_host = nil)
    @supplier_host  = supplier_host

    @processed = []
    @failures_count = 0
    @created_count  = 0
    @updated_count  = 0
    @skipped_count  = 0
    @hidden_count   = 0

    @pool = ThreadPool.new THREADS_NUM
    @logger = Logger.new LOG_FILE
  end

  private

  def log_failure_for(url, error)
    msg = "Processing #{url}... Failed: #{error}\n"
    @logger.error msg
    print msg
  end

  def log_success_for(product)
    print "Processing #{product.url}... Done\n"
  end
end
