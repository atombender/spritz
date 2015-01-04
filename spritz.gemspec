# -*- encoding: utf-8 -*-
require File.expand_path('../lib/spritz/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Alexander Staubo"]
  gem.email         = ["alex@purefiction.net"]
  gem.description   = gem.summary =
    %q{Tool for packing images into compact "sprite sheets" and otherwise managing 2D engine assets}
  gem.homepage      = 'https://github.com/alexstaubo/spritz'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "spritz"
  gem.require_paths = ["lib"]
  gem.version       = Spritz::VERSION

  gem.add_runtime_dependency 'rmagick', ['= 2.13.4']
  gem.add_runtime_dependency 'yajl-ruby', ['~> 1.1']

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rake"
end
