Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'patm'
  s.version     = '0.0.1'
  s.summary     = 'PATtern Matching library'
  s.required_ruby_version = '>= 1.9.0'

  s.author            = 'todesking'
  s.email             = 'discommucative@gmail.com'
  s.homepage          = 'https://github.com/todesking/patm'

  s.files         = `git ls-files`.split($\)
  s.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency('rspec')
end
