lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen-shopify-provisioner/version'

Gem::Specification.new do |s|
  s.name    = 'kitchen-shopify-provisioner'
  s.version = KitchenShopifyProvisioner::VERSION
  s.license = 'MIT'
  s.authors = ['Dale Hamel']
  s.email   = ['dale.hamel@shopify.com']

  s.summary     = 'Work around Shopify specific cookbook quirks'
  s.description = s.summary
  s.homepage    = 'https://github.com/shopify/kitchen-shopify-provisioner'

  s.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.test_files    = s.files.grep(/spec/)
  s.require_paths = ['lib']

  s.add_runtime_dependency 'chef',         ['~> 12']
  s.add_runtime_dependency 'test-kitchen', ['~> 1.7']
  s.add_development_dependency 'rspec', ['~> 3.4']
  s.add_development_dependency 'rake', ['~> 10.4']
end
