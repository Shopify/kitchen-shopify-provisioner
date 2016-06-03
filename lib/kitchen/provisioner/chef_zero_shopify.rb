require 'kitchen/provisioner/chef_zero'
require 'chef-config/config'
require 'chef/role'

module Kitchen
  module Provisioner

    # We'll sneak some code in before the default chef zero provisioner runs
    # This will allow us to convert our roles to JSON, and flatten at once
    class ChefZeroShopify < ChefZero
      def create_sandbox
        tmpdir = Dir.mktmpdir('chef-flattened-roles')

        at_exit do
          FileUtils.rm_rf(tmpdir)
        end

        Dir.glob(File.join(config[:roles_path], '**', '*.rb')).each do |rb_file|
          obj = ::Chef::Role.new
          obj.from_file(rb_file)
          json_file = rb_file.sub(/\.rb$/, '.json').gsub(config[:roles_path], '').sub(/^\//, '').split('/').join('--')
          File.write(File.join(tmpdir, json_file), ::Chef::JSONCompat.to_json_pretty(obj))
        end

        config[:roles_path] = tmpdir
        super
      end
    end
  end
end
