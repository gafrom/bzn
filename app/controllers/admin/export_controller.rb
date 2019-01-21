class Admin::ExportController < AdminController
  respond_to :csv, :xlsx

  before_action :update_file

  def catalog
    file = File.open Export.path_to_file(filename)
    send_file file, type: mime_type[params[:format]]
  end

  private

  def update_file
    head 404 if Export.no_file? filename

    return unless Export.obsolete? filename
    # otherwise just log it
    Rails.logger.warn "Served obsolete xlsx file. #{Export.obsolescence_message_for filename}"
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
