# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hpack/version'

Gem::Specification.new do |spec|
  spec.name          = "hpack"
  spec.version       = Hpack::VERSION
  spec.authors       = ["Konstantin Burnaev"]
  spec.email         = ["kbourn@gmail.com"]
  spec.summary       = %q{HPACK implementation for Ruby.}
  spec.description   = """Ruby implementation of the HPACK (Header Compression for HTTP/2) standard available at http://http2.github.io/http2-spec/compression.html"""
  spec.homepage      = "https://github.com/bkon/hpack"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.4", ">= 10.4.2"
  spec.add_development_dependency "simplecov", "~> 0.9", ">= 0.9.1"
  spec.add_development_dependency "rspec", "~> 3.1", ">= 3.1.0"
end
