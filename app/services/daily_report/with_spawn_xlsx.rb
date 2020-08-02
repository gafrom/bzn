module DailyReport::WithSpawnXlsx
  def spawn_xlsx(filename, ws_name)
    create_dir_unless_exists xlsx_storage_dir

    ws_name = ws_name.gsub(/[^A-Za-zА-Яа-я_\-0-9]/i, ?_)

    Xlsxtream::Workbook.open(filename) do |xlsx|
      xlsx.write_worksheet(ws_name) { |sheet| yield sheet }
    end
  end

  private

  def xlsx_storage_dir
    Rails.root.join('storage', 'export', self.class.name.underscore.split(?/).last)
  end

  def create_dir_unless_exists(dir_name)
    Dir.mkdir(dir_name) unless File.directory?(dir_name)
  end
end
