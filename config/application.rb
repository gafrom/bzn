require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bzn
  class Application < Rails::Application
    config.load_defaults 5.1
    config.eager_load_paths << Rails.root.join('lib')
    config.i18n.default_locale = :ru
  end
end
