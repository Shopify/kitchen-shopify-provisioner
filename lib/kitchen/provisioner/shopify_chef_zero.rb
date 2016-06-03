require 'find'
require 'tmpdir'
require 'fileutils'

require 'chef/role'
require 'kitchen/provisioner/chef_zero'

module Kitchen
  module Provisioner

    # We'll sneak some code in before the default chef zero provisioner runs
    # This will allow us to convert our roles to JSON, and flatten at once
    class ShopifyChefZero < ChefZero

      # Wedge our 'inject_roles' logic in between the other create_sandbox logic in the inheritance hierarchy
      # This kind of monkey patching isn't fool proof: if ChefBase or ChefZero change the logic of their
      # create_sandbox functions, those changes must be reflected here. We cannot simply call them, as
      # they will try to call super, which we can't tolerate.
      def create_sandbox
        base_sandbox
        inject_roles
        chefbase_sandbox
        chefzero_sandbox
      end

    private

      # If the implementation of Base#create_sandbox changes, copy and paste the code here
      def base_sandbox
        Kitchen::Provisioner::Base.instance_method(:create_sandbox).bind(self).call
      end

      # If the implementation of ChefBase#create_sandbox changes, copy and paste the code here
      def chefbase_sandbox
        sanity_check_sandbox_options!
        Chef::CommonSandbox.new(config, sandbox_path, instance).populate
      end

      # If the implementation of ChefZero#create_sandbox changes, copy and paste the code here
      def chefzero_sandbox
        send(:prepare_chef_client_zero_rb)
        send(:prepare_validation_pem)
        send(:prepare_client_rb)
      end

      def inject_roles
        tmpdir = Dir.mktmpdir('chef-flattened-roles')

        at_exit do
          FileUtils.rm_rf(tmpdir)
        end

        roles_path = config[:roles_path] || remote_path_join(config[:root_path], "roles")
        roles = []
        Find.find(roles_path) { |f| roles << f if f =~ /\.rb$/  }

        roles.each do |rb_file|
          obj = ::Chef::Role.new
          obj.from_file(rb_file)
          json_file = rb_file.sub(/\.rb$/, '.json').gsub(roles_path, '').split('/').select { |x| x unless x.empty? }.join('--')

          File.write(File.join(tmpdir, json_file), ::Chef::JSONCompat.to_json_pretty(obj))
        end

        config[:roles_path] = tmpdir
      end
    end
  end
end
