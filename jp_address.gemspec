$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "jp_address/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "jp_address"
  s.version     = JpAddress::VERSION
  s.authors     = ["Tad Kam"]
  s.email       = ["densya203@skult.jp"]
  s.homepage    = "https://github.com/densya203/jp_address"
  s.summary     = "Simple japan-zipcode-addresses API"
  s.description = "JpAddress is simple japan-zipcode-address-search API. You can load master-data from JapanPost and mount address-search-api to your rails application."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rubyzip"

  s.add_development_dependency "rails"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_bot_rails"
  s.add_development_dependency "webmock"
  s.add_development_dependency "vcr"
end
