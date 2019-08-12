lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rly/version'

Gem::Specification.new do |gem|
  gem.name          = 'rly'
  gem.version       = Rly::VERSION
  gem.authors       = ['Vladimir Pouzanov']
  gem.email         = ['farcaller@gmail.com']
  gem.description   = "A simple ruby implementation of lex and yacc, based on Python's ply"
  gem.summary       = "A simple ruby implementation of lex and yacc, based on Python's ply"
  gem.homepage      = ''

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake', '>= 12.0'
  gem.add_development_dependency 'rspec', '~> 3.8.0'
  gem.add_development_dependency 'rubocop', '~> 0.74.0'
  gem.add_development_dependency 'simplecov', '~> 0.17'

  if RUBY_ENGINE.to_sym == :ruby
    gem.add_development_dependency 'pry-byebug'
  end
end
