class Admin::ExportController < AdminController
  respond_to :csv, :xlsx

  before_action :check_that_file_exists

  def catalog
    file = File.open Export.path_to_file(filename)
    send_file file, type: mime_type[params[:format]]
  end

  private

  def check_that_file_exists
    head 404 if Export.no_file? filename
  end

  def mime_type
    {
      'csv'  => 'text/csv',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    }
  end

  def filename
    "#{params[:file_suffix]}.#{params[:format]}"
  end
end
