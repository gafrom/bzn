class ExportController < ApplicationController
  def mapping
    send_data Export::CSV.new.mapping, type: 'text/csv', filename: 'mapping.csv'
  end
end
