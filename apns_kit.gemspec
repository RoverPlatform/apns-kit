# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'apns_kit/version'

Gem::Specification.new do |spec|
  spec.name          = "apns_kit"
  spec.version       = ApnsKit::VERSION
  spec.authors       = ["Chris Recalis"]
  spec.email         = ["chris@rover.io"]

  spec.summary       = %q{Send push notifications using Apple's new http/2 APNs service}
  spec.homepage      = "https://github.com/RoverPlatform/apns-kit"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "http-2", "~> 0.8.1"
  spec.add_dependency "concurrent-ruby", ">= 1.0.1"
  spec.add_dependency "json", "> 0"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
