# -*- encoding: utf-8 -*-
require File.expand_path("../lib/vps/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Engel"]
  gem.email         = ["pm_engel@icloud.com"]
  gem.summary       = %q{Manage your Virtual Private Server using a user-friendly CLI}
  gem.description   = %q{Manage your Virtual Private Server using a user-friendly CLI}
  gem.homepage      = "https://github.com/archan937/vps"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "vps"
  gem.require_paths = ["lib"]
  gem.version       = VPS::VERSION
  gem.licenses      = ["MIT"]

  gem.add_dependency "thor"

  gem.add_development_dependency "pry"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "mocha"
end
