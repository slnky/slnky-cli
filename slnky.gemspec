# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slnky/version'

Gem::Specification.new do |spec|
  spec.name          = "slnky"
  spec.version       = Slnky::VERSION
  spec.authors       = ["Shawn Catanzarite"]
  spec.email         = ["me@shawncatz.com"]

  spec.summary       = %q{core slnky lib and command line}
  spec.description   = %q{core slnky lib and command line}
  spec.homepage      = "https://github.com/slnky/slnky-cli"
  spec.license       = "MIT"

  # # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|scripts)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^#{spec.bindir}/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency 'dotenv', '~> 2.1.0'
  spec.add_dependency 'amqp', '~> 1.5.1'
  spec.add_dependency 'clamp', '~> 1.0.0'
  spec.add_dependency 'activesupport', '~> 4.2.5.1'
  spec.add_dependency 'tilt', '~> 2.0.2'
  spec.add_dependency 'eventmachine', '~> 1.0.9.1'
  spec.add_dependency 'rest-client', '~> 1.8.0'
  spec.add_dependency 'slop', '~> 4.3.0'
end
