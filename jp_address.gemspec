require_relative "lib/jp_address/version"

Gem::Specification.new do |s|
  s.name        = "jp_address"
  s.version     = JpAddress::VERSION
  s.authors     = ["Tad Kam"]
  s.email       = ["densya203@skult.jp"]
  s.homepage    = "https://github.com/densya203/jp_address"
  s.summary     = "Simple japan-zipcode-addresses API"
  s.description = "JpAddress is simple japan-zipcode-address-search API. You can load master-data from JapanPost and mount address-search-api to your rails application."
  s.license     = "MIT"

  s.required_ruby_version = ">= 3.1.0"

  s.metadata = {
    "homepage_uri"          => s.homepage,
    "source_code_uri"       => "#{s.homepage}/tree/v#{JpAddress::VERSION}",
    "bug_tracker_uri"       => "#{s.homepage}/issues",
    "changelog_uri"         => "#{s.homepage}/blob/master/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  s.require_paths = ["lib"]

  s.add_dependency "railties", ">= 7.1", "< 9.0"
  s.add_dependency "activerecord", ">= 7.1", "< 9.0"
  s.add_dependency "rubyzip", ">= 2.3", "< 4.0"
  # csv is a bundled gem since Ruby 3.4, so it has to be declared explicitly.
  s.add_dependency "csv", ">= 3.0", "< 4.0"
end
