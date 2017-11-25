class ExportController < ApplicationController
  def mapping
    send_data Export::CSV.new.mapping, type: 'text/csv', filename: 'mapping.csv'
  end

  def catalog
    filename = "#{Export::PATH_TO_FILE}_additions_batch_#{params[:batch_index]}.csv"
    send_file File.open(filename)
  end
end
