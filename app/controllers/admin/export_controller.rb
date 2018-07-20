class Admin::ExportController < AdminController
  respond_to :csv, :xlsx

  before_action :update_file

  def catalog
    file = File.open path_to_file
    send_file file, type: mime_type[params[:format]]
  end

  private

  def update_file
    return unless obsolete?
    Rake::Task["export:#{params[:format]}:wb"].invoke
  end

  def mime_type
    {
      'csv'  => 'text/csv',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    }
  end

  def obsolete?
    no_file? || latest_updated_product.updated_at > file_modified_at
  end

  def path_to_file
    "#{Export::PATH_TO_FILE}_#{params[:file_suffix]}.#{params[:format]}"
  end

  def file_modified_at
    File.mtime path_to_file
  end

  def latest_updated_product
    Product.where(supplier_id: 12).order(updated_at: :desc).first
  end

  def no_file?
    dir = File.dirname path_to_file
    Dir.mkdir dir unless File.directory? dir

    !File.exists? path_to_file
  end
end
