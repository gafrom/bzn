module AngelaRicci
  class Categorizer
    SCHEDULE = {
      'П'  => [3, 'Платья'],
      'ПБ' => [3, 'Платья больших размеров'],
      'Т'  => [5, 'Блузки и топы'],
      'Б'  => [7, 'Брюки'],
      'К'  => [4, 'Костюмы'],
      'ВД' => [2, 'Дублёнки'],
      'ВК' => [2, 'Верхняя одежда'],
      'С'  => [9, 'Спортивная одежда'],
      'Ю'  => [8, 'Юбки']
    }

    attr_reader :key, :code, :collection

    def initialize(title)
      @title = title
      @key, @code = params_from_title
      @collection = SCHEDULE.fetch(@key).second
    end

    def category_id
      @category_id ||= begin
        ::Categorizer.new.from_title(@title).id
      rescue NotImplementedError
        SCHEDULE.fetch(@key).first
      end
    end

    def category
      @category ||= Category.find category_id
    end

    private

    def params_from_title
      match = @title.match(/\A(?:.*\s)?(?<key>[А-Я]{1,3})\s(?<code>\d+)/)
      return match[:key], match[:code].to_i if match

      msg = "[PARSING ERROR] cannot infer key and code from title: '#{@title}'"
      raise NotImplementedError, msg
    end
  end
end
