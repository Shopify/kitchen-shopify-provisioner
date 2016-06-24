require 'kitchen/provisioner/chef_zero'
require 'chef-config/config'
require 'chef/role'
require 'chef/data_bag_item'
require 'chef/encrypted_data_bag_item'
require 'chef/encrypted_data_bag_item/check_encrypted'

module Kitchen
  module Provisioner
    # We'll sneak some code in before the default chef zero provisioner runs
    # This will allow us to convert our roles to JSON, and flatten at once
    class ChefZeroShopify < ChefZero
      def create_sandbox
        tmpdir = Dir.mktmpdir('chef-shopify-inject')

        at_exit do
          FileUtils.rm_rf(tmpdir)
        end

        flatten_roles(config, tmpdir) if config[:roles_path]
        write_data_bag_key(config, tmpdir) if config[:data_bag_secret] && config[:encrypted_data_bag_secret_key_path]
        decrypt_data_bags(config, tmpdir) if config[:data_bags_path]
        super
      rescue => e
        puts e.message
        puts e.backtrace
        raise 'Failed extend the shopify provisioner!'
      end

      private

      def flatten_roles(config, tmpdir)
        # This block generates exceptions if we don't have a roles directory in ./
        #   or :roles_path is not configured in .kitchen.yml.
        flat_roles = File.join(tmpdir, 'roles')
        FileUtils.mkdir_p(flat_roles)

        Dir.glob(File.join(config[:roles_path], '**', '*.rb')).each do |rb_file|
          obj = ::Chef::Role.new
          obj.from_file(rb_file)
          json_file = rb_file.sub(/\.rb$/, '.json').gsub(config[:roles_path], '').sub(%r{^\/}, '').split('/').join('--')
          File.write(File.join(flat_roles, json_file), ::Chef::JSONCompat.to_json_pretty(obj))
        end

        config[:roles_path] = flat_roles
      end

      def write_data_bag_key(config, tmpdir)
        path = File.join(tmpdir, 'encrypted_data_bag_secret')
        File.write(path, config[:data_bag_secret].strip)
        config[:encrypted_data_bag_secret_key_path] = path
      end

      def decrypt_data_bags(config, tmpdir)
        plain_data_bags = File.join(tmpdir, 'data_bags')
        secret = File.read(config[:encrypted_data_bag_secret_key_path]).strip

        data_bags = Dir.glob(File.join(config[:data_bags_path], '*'))
        data_bags.each do |data_bag|
          bag_name = File.basename(data_bag)
          files = Dir.glob(File.join(data_bag, '*.json')).flatten
          files.each do |item_file|
            raw_data = ::Chef::JSONCompat.from_json(IO.read(item_file))
            raw_data = ::Chef::EncryptedDataBagItem.new(raw_data, secret).to_hash if encrypted_data_bag?(raw_data)
            item = ::Chef::DataBagItem.new
            item.data_bag(bag_name)
            item.raw_data = raw_data
            json_dump = ::Chef::JSONCompat.to_json_pretty(item)
            plain_file = File.join(plain_data_bags, bag_name, File.basename(item_file))
            FileUtils.mkdir_p(File.dirname(plain_file))
            File.write(plain_file, json_dump)
          end
        end
        config[:data_bags_path] = plain_data_bags
      end

      def encrypted_data_bag?(raw_data)
        Class.new.extend(::Chef::EncryptedDataBagItem::CheckEncrypted).encrypted?(raw_data)
      end
    end
  end
end
