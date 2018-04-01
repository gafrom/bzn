module Gepur
  module Propertizer
    # [{1=>"Мини"}, {2=>"Миди"}, {3=>"Макси"}, {4=>"Выходная"}, {5=>"Повседневная"}, {6=>"Домашняя"}]
    SCHEDULE = {
      26 => 4, # Вечерние
      28 => 1, # Мини
      29 => 2, # Миди
      30 => 3, # Макси
      174 => 4 # "На выпускной"
    }.freeze

    def self.categories_to_properties(ids)
      ids.map { |id| SCHEDULE[id.to_i] }.compact!
    end
  end
end
