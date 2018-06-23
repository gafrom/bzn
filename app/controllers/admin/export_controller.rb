class Admin::ExportController < AdminController
  def catalog
    file = File.open "#{Export::PATH_TO_FILE}_#{params[:file_suffix]}.csv"
    send_file file, type: 'text/csv'
  end
end
