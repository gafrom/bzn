module Export
  module Pushable
    def push_to(file, batch, strategy = :full)
      batch.each { |product| product.rows(strategy).each { |row| file << row } }
    end
  end
end
