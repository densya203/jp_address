require_relative 'boot'

# Pick the frameworks you want:
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)
require 'jp_address'

module Dummy
  class Application < Rails::Application
    # Follow the defaults of whatever Rails version the specs run against.
    config.load_defaults Rails::VERSION::STRING.to_f

    # The dummy app only exists to host the engine while the specs run.
    config.eager_load = false
  end
end
