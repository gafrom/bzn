module Catalogue
  module WithErrorsCaught
    def catch_errors_for(*method_names)
      wrapping_module = if defined? self::ErrorsCatcher
                          self.const_get('ErrorsCatcher')
                        else
                          self.const_set('ErrorsCatcher', Module.new)
                        end

      wrapping_module.class_eval do
        method_names.each do |method_name|
          define_method(method_name) do |*args|
            begin
              super *args
              spit_results method_name, only_once: true
            rescue StandardError => ex
              @logger.error ex
              spit_results method_name
              raise ex
            end
          end
        end
      end

      prepend wrapping_module
    end
  end
end
