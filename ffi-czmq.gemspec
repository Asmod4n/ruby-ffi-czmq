$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'czmq/version'

Gem::Specification.new do |gem|
  gem.authors      = %w[Hendrik Beskow]
  gem.description  = 'czmq ffi wrapper'
  gem.summary      = gem.description
  gem.homepage     = 'https://github.com/Asmod4n/ruby-ffi-czmq'
  gem.license      = 'Apache-2.0'

  gem.name         = 'ffi-czmq'
  gem.files        = Dir['README.md', 'LICENSE', 'lib/**/*']
  gem.version      = CZMQ::VERSION

  gem.required_ruby_version = '>= 1.9.3'
  gem.add_dependency 'ffi', '>= 1.9.5'
  gem.add_development_dependency 'bundler', '>= 1.7'
end
