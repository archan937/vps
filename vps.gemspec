# -*- encoding: utf-8 -*-
require File.expand_path("../lib/vps/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paul Engel"]
  gem.email         = ["pm_engel@icloud.com"]
  gem.summary       = %q{Zero-config deployments of Plug, Phoenix, Rack and Rails apps on a clean Ubuntu server using Docker and Let's Encrypt}
  gem.description   = %q{Zero-config deployments of Plug, Phoenix, Rack and Rails apps on a clean Ubuntu server using Docker and Let's Encrypt}
  gem.homepage      = "https://github.com/archan937/vps"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "vps"
  gem.require_paths = ["lib"]
  gem.version       = VPS::VERSION
  gem.licenses      = ["MIT"]

  gem.add_dependency "thor"
  gem.add_dependency "erubis"
  gem.add_dependency "inquirer"
  gem.add_dependency "net-ssh"
  gem.add_dependency "activesupport", ">= 4.1.8"

  gem.add_development_dependency "pry"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "mocha"
end
