class Chef
  class Resource
    # Chef Resource for declaring a service for Elasticsearch
    class ElasticsearchService < Chef::Resource::LWRPBase
      resource_name :elasticsearch_service

      actions(:configure, :remove)
      default_action :configure

      attribute(:service_name, kind_of: String, name_attribute: true)
      attribute(:node_name, kind_of: String, default: nil)
      attribute(:path_conf, kind_of: String, default: '/usr/local/etc/elasticsearch')
      attribute(:bindir, kind_of: String, default: '/usr/local/bin')
      attribute(:args, kind_of: String, default: '-d')

      attribute(:pid_path, kind_of: String, default: '/usr/local/var/run')
      attribute(:pid_file, kind_of: String, default: nil)

      attribute(:user, kind_of: String, name_attribute: true) # default to resource name

      # default user limits
      attribute(:memlock_limit, kind_of: String, default: 'unlimited')
      attribute(:nofile_limit, kind_of: String, default: '64000')
    end
  end
end
