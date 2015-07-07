class Chef
  class Resource
    class ElasticsearchPlugin < Chef::Resource::LWRPBase
      include ElasticsearchCookbook::Helpers
      resource_name :elasticsearch_plugin

      actions(:install, :remove)
      default_action :install

      # /usr/local/awesome/elasticsearch-version/plugins or packaged location
      attribute(:plugin_dir, kind_of: String)
      attribute(:bindir, kind_of: String, default: '/usr/local/bin')

      attribute(:plugin_name, kind_of: String, name_attribute: true)
      attribute(:version, kind_of: String)
      attribute(:url, kind_of: String)

      attribute(:user, kind_of: String, default: 'elasticsearch')
      attribute(:group, kind_of: String, default: 'elasticsearch')
    end
  end
end
