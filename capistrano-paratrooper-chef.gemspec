# -*- encoding: utf-8 -*-
require File.expand_path('../lib/capistrano-paratrooper-chef/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Takeshi KOMIYA"]
  gem.email         = ["i.tkomiya@gmail.com"]
  gem.description   = %q{A capistrano task to invoke chef-solo}
  gem.summary       = %q{A capistrano task to invoke chef-solo}
  gem.homepage      = "https://github.com/tk0miya/capistrano-paratrooper-chef"
  gem.license       = "Apache 2.0"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-paratrooper-chef"
  gem.require_paths = ["lib"]
  gem.version       = Capistrano::Paratrooper::Chef::VERSION

  gem.add_dependency("capistrano", "~> 2.14")
end
