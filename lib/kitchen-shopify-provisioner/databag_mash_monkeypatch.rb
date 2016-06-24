# because https://github.com/chef/chef-zero/pull/147/files will never get merged

module ChefZero
  module ChefData
    class DataNormalizer
      def self.normalize_data_bag_item(data_bag_item, data_bag_name, id, method)
        if method == 'DELETE'
          # TODO SERIOUSLY, WHO DOES THIS MANY EXCEPTIONS IN THEIR INTERFACE
          unless data_bag_item['json_class'] == 'Chef::DataBagItem' && data_bag_item['raw_data']
            data_bag_item['id'] ||= id
            data_bag_item = { 'raw_data' => data_bag_item }
            data_bag_item['chef_type'] ||= 'data_bag_item'
            data_bag_item['json_class'] ||= 'Chef::DataBagItem'
            data_bag_item['data_bag'] ||= data_bag_name
            data_bag_item['name'] ||= "data_bag_item_#{data_bag_name}_#{id}"
          end
        else
          # If it's not already wrapped with raw_data, wrap it.
          if data_bag_item['json_class'] == 'Chef::DataBagItem' && data_bag_item['raw_data']
            # data_bag_item = data_bag_item['raw_data']
          end
          # Argh.  We don't do this on GET, but we do on PUT and POST????
          if %w(PUT POST).include?(method)
            data_bag_item['chef_type'] ||= 'data_bag_item'
            data_bag_item['data_bag'] ||= data_bag_name
          end
          data_bag_item['id'] ||= id
        end
        data_bag_item
      end
    end
  end
end
