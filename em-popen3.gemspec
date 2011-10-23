$:.push File.expand_path('../lib', __FILE__)
require 'em-popen3/version'

Gem::Specification.new do |s|
  s.name              = 'em-popen3'
  s.version           = EventMachine::POpen3::VERSION

  s.authors           = ['stask']
  s.email             = ['stask@kontera.com']
  s.summary           = "Adds popen3 support to eventmachine"
  s.description       = s.summary
  s.rubyforge_project = 'em-popen3'

  s.add_dependency      'eventmachine', '>= 1.0.0.beta.4'

  s.files             = `git ls-files`.split("\n")
  s.require_paths     = ['lib']
end
