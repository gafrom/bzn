class ExportController < ApplicationController
  def mapping
    send_data Export::CSV.new.mapping, type: 'text/csv', filename: 'mapping.csv'
  end

  def catalog
    filename = "#{Export::PATH_TO_FILE}#{params[:file_suffix]}.csv"
    send_file File.open(filename)
  end
end
