ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require_relative 'dummy/config/environment'

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'
require 'webmock/rspec'

# The dummy app carries no migrations of its own, so load the schema that
# mirrors the engine's db/migrate before the suite runs.
ActiveRecord::Schema.verbose = false
load Rails.root.join('db/schema.rb')

# factory_bot_rails looks for factories under the dummy app's Rails.root, so
# point it at the engine's own spec/factories instead.
FactoryBot.definition_file_paths = [File.expand_path('factories', __dir__)]
FactoryBot.reload

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
