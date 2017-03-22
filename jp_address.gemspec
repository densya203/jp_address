$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "jp_address/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "jp_address"
  s.version     = JpAddress::VERSION
  s.authors     = ["Tadashi K"]
  s.email       = ["densya203@skult.jp"]
  s.homepage    = "https://github.com/densya203/jp_address"
  s.summary     = "Simple japan-zipcode-addresses API"
  s.description = "JpAddress is simple japan-zipcode-addresses API. You can add address-search-api, and loading master-data script."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rubyzip"

  s.add_development_dependency "rails"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "webmock"
  s.add_development_dependency "vcr"
end
