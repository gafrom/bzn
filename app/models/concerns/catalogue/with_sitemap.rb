module Catalogue::WithSitemap
  private

  def extract_sitemap_links(url, &block)
    full_url = "#{supplier.host}#{url}"
    print "Updating links from #{full_url} ... "
    links = nil
    CSV.open path_to_file(:links), 'wb' do |file|
      links = extract_from_xml ungzipped_io(full_url).read
      links = links.select &block if block
      links.each { |url, modified_at| file << [url, modified_at] }
    end
    puts "💃  Done. Extracted #{links.size} links."
  end

  def ungzipped_io(url)
    io = open url
    return io if url[-3..-1] != '.gz'

    Zlib::GzipReader.new io
  end

  def process_links
    CSV.foreach path_to_file(:links) do |link|
      url, modified_at = link
      product = Product.find_or_initialize_by remote_key: url, supplier: supplier

      if product_fresh? product, modified_at
        @processed << product.id
        next skip product
      end

      @pool.run { synchronize url, product }
      # synchronize url, product
    end

    @pool.await_completion
    hide_removed_products

    puts "Created: #{@created_count}\n" \
         "Updated: #{@updated_count}\n" \
         "Skipped: #{@skipped_count}\n" \
         "Hidden: #{@hidden_count}\n" \
         "Failures: #{@failures_count}"
  end

  def product_fresh?(product, modified_at_as_string)
    return if ENV['invalidate_all'].present?

    updated_at = product.updated_at
    updated_at && updated_at > modified_at_as_string.to_date
  end

  def extract_from_xml(content)
    Nokogiri::XML(content).css('url').inject({}) do |links, node|
      url = node.css('loc').first.text.split(supplier.host).last
      modified_at = node.css('lastmod').first.text.to_date

      next links.merge!({ url => modified_at }) if url && modified_at

      log_failure_for url, '[SITEMAP PARSING]'
      links
    end
  end
end
