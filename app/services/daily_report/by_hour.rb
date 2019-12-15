require 'numo/narray'

class DailyReport::ByHour < DailyReport::Base
  NUM_HOURS = 24
  PRODUCT_ID   = 'product_id'.freeze
  REMOTE_ID    = 'remote_id'.freeze
  CREATED_AT   = 'created_at'.freeze
  SIZES        = 'sizes'.freeze
  CURLY_BRACES = '{}'.freeze
  COMMA        = ?,.freeze

  def initialize(task)
    super
    @facts_ids_query = HourlyFact.where(created_at: @start_at..@end_at)
                                 .order(:product_id, :created_at)
  end

  def store
    Xlsxtream::Workbook.open @filename do |xlsx|
      xlsx.write_worksheet I18n.l(Time.now, format: :xlsx) do |sheet|
        sheet << pre_headers
        sheet << headers

        # a placeholder for remote_id in the loops below
        remote_id = nil
        # simple counter, indices of sizes, keys denote 1st dimension in 3D array
        size_indexing = Hash.new { |hsh, key| hsh[key] = hsh.size }
        # a placeholder for 3D array of [sizes.size, num_days (in report), 24 (hours)]
        arr3d = nil

        batches_of_facts_ids do |ids|
          HourlyFact.pluck_fields_for_report(ids).each do |fact|
            if remote_id != fact[REMOTE_ID]
              flush! arr3d, sheet, remote_id, size_indexing

              arr3d = nil
              (remote_id = fact[REMOTE_ID].freeze) || next
            end

            axes0 = fact[SIZES].delete!(CURLY_BRACES)
                               .split(COMMA)
                               .map { |size_name| size_indexing[size_name] }
            next if axes0.empty?

            datetime = fact[CREATED_AT].to_time
            axis1 = @date_indexing[datetime.to_date]
            axis2 = datetime.hour

            arr3d = expand_if_necessary(arr3d, axes0.max + 1)

            arr3d[axes0, axis1, axis2] = 1
          end
        end

        flush! arr3d, sheet, remote_id, size_indexing
      end
    end
  end

  private

  def build_zeros(axis0_size)
    Numo::Int8.zeros(axis0_size, @num_days, NUM_HOURS)
  end

  def expand_if_necessary(arr3d, max_axis0_size)
    if arr3d
      diff = max_axis0_size - arr3d.shape.first
      diff > 0 ? arr3d.concatenate(build_zeros(diff)) : arr3d
    else
      build_zeros(max_axis0_size)
    end
  end

  def build_error_counts_by_days(arr3d)
    (NUM_HOURS - arr3d.max(axis: 0).sum(axis: 1)).to_a.map { |n| n if n != 0 }
  end

  def flush!(arr3d, output, remote_id, size_indexing)
    return unless arr3d && remote_id

    error_counts_by_days = build_error_counts_by_days(arr3d)
    invert_size_indexing = size_indexing.invert

    arr3d.sum(axis: 2).each_over_axis.each_with_index do |size_counts, i|
      size_name = invert_size_indexing[i]
      output << [remote_id, size_name, *size_counts, nil, *error_counts_by_days]

      # sweeping the floor
      invert_size_indexing.delete i
      size_indexing.delete size_name
    end
  end

  def pre_headers
    [
      nil, nil, 'Количество часов присутствия размера', *[nil] * (@num_days - 1), nil,
      'Отсутствующие данные (в идеале должно быть пусто)'
    ]
  end

  def headers
    result = ['remote_id', 'size_name']

    # columns for valid data
    @num_days.times do |n|
      result << I18n.l(@start_at + n.days, format: :xlsx)
    end

    # separator column
    result << nil

    # columns for errors (ideally all data in these columns should be empty)
    @num_days.times do |n|
      result << 'E' + I18n.l(@start_at + n.days, format: :xlsx)
    end

    result
  end
end
