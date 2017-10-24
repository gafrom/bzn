require 'open-uri'
require 'csv'

module VeraNova
  class Catalog
    HOST = 'veranova.ru'
    STALE_IN = 10.hours
    THREADS_NUM = 24
    LOG_FILE = Rails.root.join 'log', 'parsing.log'
    LINKS_LIST_FILE = Rails.root.join 'storage', "#{self.name.underscore}.links"
    LINKS_LIST_URL = URI 'http://veranova.ru/sitemap-product.xml'

    def initialize
      @failures_count = 0
      @success_count  = 0
      @skipped_count  = 0
      @pool = ThreadPool.new THREADS_NUM
      @logger = Logger.new LOG_FILE
    end

    def sync
      ensure_links_are_fresh
      process_links
    end

    private

    def ensure_links_are_fresh
      update_links if empty? || (last_modified_at + STALE_IN).past?
    end

    def process_links
      CSV.foreach LINKS_LIST_FILE do |link|
        url, modified_at = link
        product = Product.find_or_initialize_by remote_key: url, supplier: VeraNova.supplier
        next skip url if fresh? product, modified_at

        @pool.run { synchronize url, product }
      end

      @pool.await_completion

      puts "Successes: #{@success_count}\n" \
           "Failures: #{@failures_count}\n" \
           "Not modified: #{@skipped_count}"
    end

    def synchronize(url, product)
      attrs = parse URI("http://#{HOST}#{url}")
      all_attrs = attrs.merge url: url

      product.update all_attrs
      log_success_for product
      @success_count += 1
    rescue NoMethodError, NotImplementedError => error
      log_failure_for product.url, error.message
      @failures_count += 1
    end

    # in case a product's web page is not modified
    def skip(url)
      @skipped_count += 1
      puts "Processing #{url}... Skipped"
    end

    def parse(uri)
      page = Nokogiri::HTML open(uri)
      product_attributes_from page
    end

    def product_attributes_from(page)
      attrs = {}
      attrs[:title] = page.css('[itemprop="name"]').first.text
      attrs[:category] = Categorizer.new.from_title attrs[:title]
      attrs[:price] = page.css('#formated_price').first.attr('price').to_i
      desc = page.css('[itemprop="model"]').first.text
      attrs[:description] = desc.blank? ? '' : "<p class='fabric'>Состав: #{desc}</p>"
      attrs[:description] << page.css('#tab-description').first.to_html.gsub("\n", ' ').squeeze(' ')
      attrs[:images] = page.css('#one-image>.item>img')
                           .map { |img| img.attr('src').split(HOST).second }
      attrs[:sizes] = page.css('#product .owq-name').map { |el| el.text }
      attrs[:is_available] = attrs[:price] > 0
      attrs.merge compare_price: attrs[:price] * 2
      # no color available at the web site
      # no collection available at the web site
      attrs
    end

    def update_links
      print "Updating links from #{LINKS_LIST_URL}... "
      CSV.open LINKS_LIST_FILE, 'wb' do |file|
        links = extract_links open(LINKS_LIST_URL).read
        links.each { |url, modified_at| file << [url, modified_at] }
      end
      puts 'Done'
    end

    def fresh?(product, modified_at_as_string)
      updated_at = product.updated_at
      updated_at && updated_at > modified_at_as_string.to_date
    end

    def empty?
      dir = File.dirname LINKS_LIST_FILE
      Dir.mkdir dir unless File.directory? dir

      !File.exists? LINKS_LIST_FILE
    end

    def last_modified_at
      File.mtime LINKS_LIST_FILE
    end

    def extract_links(content)
      Nokogiri::XML(content).css('url').inject({}) do |links, node|
        url = node.css('loc').first.text.split(HOST).last
        modified_at = node.css('lastmod').first.text.to_date
        log_failure_for url, '[SITEMAP PARSING]' unless url && modified_at

        links.merge! url => modified_at
      end
    end

    def log_failure_for(url, error)
      msg = "Processing #{url}... Failed: #{error}\n"
      @logger.error msg
      print msg
    end

    def log_success_for(product)
      print "Processing #{product.url}... Done\n"
    end
  end
end
