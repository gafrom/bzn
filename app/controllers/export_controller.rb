class ExportController < ApplicationController
  def mapping
    send_data Export::CSV.new.mapping, type: 'text/csv', filename: 'mapping.csv'
  end

  def catalog
    ext = params[:file_suffix] ? 'csv' : 'xlsx'
    filename = "#{Export::PATH_TO_FILE}#{params[:file_suffix]}.#{ext}"
    send_file File.open(filename)
  end
end
