# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hiera/backend/eyaml/encryptors/gpg/version'

Gem::Specification.new do |gem|
  gem.name          = "hiera-eyaml-gpg_ruby"
  gem.version       = Hiera::Backend::Eyaml::Encryptors::Gpg::VERSION
  gem.description   = "GPG encryptor for use with hiera-eyaml, in pure Ruby"
  gem.summary       = "Encryption plugin for hiera-eyaml backend for Hiera, in pure Ruby"
  gem.author        = "Raphaël Pinson"
  gem.license       = "MIT"

  gem.homepage      = "http://github.com/raphink/hiera-eyaml-gpg_ruby"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('hiera-eyaml', '>=1.3.8')
  gem.add_dependency('ruby_gpg', '>=0.3.0')
end
